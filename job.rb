# frozen_string_literal: true

require_relative './environment'

# Fetches GH Project Issues
class Job
  class << self
    def handle_rate_limit(response)
      return unless response.respond_to?(:headers) && response.headers

      remaining = response.headers['x-ratelimit-remaining'].to_i
      reset_time = response.headers['x-ratelimit-reset'].to_i
      limit = response.headers['x-ratelimit-limit'].to_i

      return unless remaining < 10

      sleep_time = [reset_time - Time.now.to_i, 0].max
      $logger.info "Rate limit almost exceeded, sleeping for #{sleep_time} seconds..."
      sleep(sleep_time)
    end

    def persist_issues(project_info, sprints, issues)
      project = Project.find_or_initialize_by(number: project_info[:number]).tap do |project|
        project.title = project_info[:title]
        project.number = project_info[:number]
        project.public = project_info[:public]
        project.closed = project_info[:closed]
        project.url = project_info[:url]
        project.save
      end

      sprints.map! do |sprint_data|
        Sprint.find_or_initialize_by(iteration_id: sprint_data[:iteration_id]).tap do |sprint|
          sprint.assign_attributes(
            title: sprint_data[:title],
            start_date: sprint_data[:start_date],
            duration: sprint_data[:duration],
            project_id: project.id
          )
          sprint.save
        end
      end

      issues.each do |issue_data|
        issue = Issue.find_or_initialize_by(number: issue_data[:content][:number])
        issue.title = issue_data[:content][:title]
        iteration_id =
          issue_data[:fieldValues][:nodes]
          .select { |node| node.dig(:field, :name) == 'Sprint' && node.key?(:iterationId) }
          .first&.dig(:iterationId)

        sprints.each do |sprint|
          issue_sprint = IssuesSprint.with_removed.find_by(issue:, sprint:)

          if issue_sprint
            issue_sprint.restore if issue_sprint.removed?
          elsif sprint.iteration_id == iteration_id
            # Use issue's created_at if we're importing for the first time as when it was added is not available
            issue_sprint = IssuesSprint.with_removed.new(issue:, sprint:)
            created_at = sprint.project.created_at > 1.hour.ago ? issue_data[:content][:createdAt] : Time.now
            issue_sprint.created_at = created_at
            issue_sprint.save
          end
        end

        # Soft remove issues that are no longer in the sprint
        issue.issues_sprints.each do |issue_sprint|
          next if issue_sprint.removed? || issue_sprint.sprint.iteration_id == iteration_id

          issue_sprint.remove
        end

        fields = issue_data[:fieldValues][:nodes].map do |node|
          next unless node[:field] && node[:field][:name]

          key = node[:field][:name]
          value = node[:text] || node[:name] || node[:number] || node[:title]
          [key, value]
        end.compact.to_h
        issue.points = fields['Points'] || fields['Estimate']
        issue.status = fields['Status']
        issue.state = issue_data[:content][:state]
        issue.url = issue_data[:content][:url]
        issue.data = issue_data.to_h
        issue.closed_at = issue_data[:content][:closedAt]
        issue.created_at = issue_data[:content][:createdAt] if issue_data[:content][:createdAt].present?
        issue.save
      end
    end

    def run(projects = Project.all)
      if projects.empty?
        ENV['SEED_GH_PROJECT_URLS'].split(',').each do |url|
          number = url.match(%r{github.com/orgs/[^/]+/projects/(\d+)}).captures.first
          Project.create(number:, url:)
        end
      end

      projects.each do |project|
        organization, number = project.url.match(%r{github.com/orgs/([^/]+)/projects/(\d+)}).captures
        github_project = Github::Project.new(token: ENV.fetch('GH_TOKEN'), organization:, number:)

        begin
          response = github_project.query(github_project.build_query)
          handle_rate_limit(response)

          persist_issues github_project.info, github_project.active_sprints, github_project.issues
        rescue => e
          $logger.error "Error fetching project data: #{e.message}"
          $logger.error e.backtrace.join("\n")
        end
      end

      $logger.info 'Finished Job.' # rubocop:disable Style/GlobalVars
    end
  end
end

# rubocop:disable Style/GlobalVars
if __FILE__ == $PROGRAM_NAME
  $logger.info('Starting Job.')

  # Run the job
  loop do
    Job.run
    $logger.info "Sleeping until #{Time.now + 10.minutes}..."
    sleep 60 * 10
  end

  $logger.error('Job exited.')
  exit 1
end
# rubocop:enable Style/GlobalVars
