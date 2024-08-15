# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

$LOAD_PATH.unshift 'lib'
require 'logger'

require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']

require 'dotenv'
require 'github/project'

require 'active_record'
require_relative './models/issue'
require_relative './models/issues_sprint'
require_relative './models/sprint'
require_relative './models/project'

# Fetches GH Project Issues
class Job
  class << self
    attr_accessor :logger

    def persist_issues(project_info, issues)
      project = Project.find_or_initialize_by(number: project_info[:number]).tap do |project|
        project.title = project_info[:title]
        project.number = project_info[:number]
        project.closed = project_info[:closed]
        project.url = project_info[:url]
        project.save
      end

      issues.each do |issue_data|
        sprints =
          issue_data[:fieldValues][:nodes]
          .select { |node| node[:field] && node[:field][:name] == 'Sprint' }
          .map do |sprint_data|
            Sprint.find_or_initialize_by(iteration_id: sprint_data[:iterationId]).tap do |sprint|
              sprint.assign_attributes(
                title: sprint_data[:title],
                start_date: sprint_data[:startDate],
                duration: sprint_data[:duration],
                project_id: project.id
              )
              sprint.save
            end
          end

        issue = Issue.find_or_initialize_by(number: issue_data[:content][:number])
        issue.title = issue_data[:content][:title]
        sprints.each do |sprint|
          next if issue.sprints.include?(sprint)

          issue.sprints << sprint
        end

        fields = issue_data[:fieldValues][:nodes].map do |node|
          next unless node[:field] && node[:field][:name]

          key = node[:field][:name]
          value = node[:text] || node[:name] || node[:number] || node[:title]
          [key, value]
        end.compact.to_h
        issue.points = fields['Points']
        issue.status = fields['Status']
        issue.state = issue_data[:content][:state]
        issue.url = issue_data[:content][:url]
        issue.data = issue_data
        issue.closed_at = issue_data[:content][:closedAt]
        issue.save
      end
    end

    def run
      Project.all.each do |project|
        organization, number = project.url.match(%r{github.com/orgs/([^/]+)/projects/(\d+)}).captures
        project = Github::Project.new(token: ENV.fetch('GH_TOKEN'), organization:, number:)
        persist_issues project.info, project.issues
      end

      puts 'Done.'
    end
  end
end

# Ensure the database connection is established
ActiveRecord::Base.establish_connection(
  ENV['DATABASE_URL'] || 'postgres://postgres:password@postgres:5432/oge-smarthours-pricing'
)

Job.logger = Logger.new($stdout)
Job.logger.info('Starting Job.')

# Run the job
# loop do
  Job.run
exit
  # Job.logger.info "Sleeping until #{Time.now + 1.hour}..."
  # sleep 60 * 60 * 1 # 1 hour
# end

# Job.logger.error('Job exited.')
# exit 1
