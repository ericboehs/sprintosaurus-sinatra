require 'octokit'

module Github
  class Project
    attr_accessor :token, :organization, :repo, :number

    def initialize(token:, organization:, repo:, number:)
      @token = token
      @organization = organization
      @repo = repo
      @number = number
    end

    def snapshot_board
      puts JSON.pretty_generate issue_ids_by_status
    end

    def add_issue(issue_id: nil, issue_number: nil)
      raise 'Missing args' if issue_id.nil? && issue_number.nil?

      issue_id ||= issue_node_id issue_number

      query <<-GRAPHQL
      mutation {
        addProjectV2ItemById(input: {projectId: "#{node_id}" contentId: "#{issue_id}"}) {item {id}}
      }
      GRAPHQL
    end

    def set_issue_field(issue_id:, field_node_id:, option_node_id: nil, value: nil)
      value = %(text: #{value}) if value.is_a? String
      value = %(number: #{value}) if value.is_a? Numeric
      value = %(singleSelectOptionId: "#{option_node_id}") if option_node_id
      query <<-GRAPHQL
      mutation {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: "#{node_id}"
            itemId: "#{issue_id}"
            fieldId: "#{field_node_id}"
            value: {
              #{value}
            }
          }
        ) {
          projectV2Item {
            id
          }
        }
      }
      GRAPHQL
    end

    def remove_all_issues(exclude_closed: false)
      $stdout.puts "Removing all issues from GH Project #{number}."

      remove_issues ids: issue_ids(exclude_closed:)
    end

    def remove_issues(ids:)
      Async do
        semaphore = Async::Semaphore.new 10

        ids.map do |id|
          semaphore.async { remove_issue issue_id: id }
        end.map(&:wait)
      end
    end

    def remove_issue(issue_id:)
      query <<-GRAPHQL
      mutation {
        deleteProjectV2Item(
          input: {
            projectId: "#{node_id}"
            itemId: "#{issue_id}"
          }
        ) {
          deletedItemId
        }
      }
      GRAPHQL
    end

    def node_for_field(field_name)
      query(
        %{
          query{
            node(id: "#{node_id}") {
            ... on ProjectV2 { fields(first: 20) { nodes { ... on ProjectV2Field { id name } ... on ProjectV2IterationField { id name configuration { iterations { startDate id }}} ... on ProjectV2SingleSelectField { id name options { id name }}}}}
            }
          }
        }
      )[:data][:node][:fields][:nodes].find { |field| field[:name] == field_name }
    end

    def issue_node_id(issue_number)
      query(
        %{query{repository(owner: "#{organization}", name: "#{repo}") {issue(number: #{issue_number}){id}}}}
      )[:data][:repository][:issue][:id]
    end

    def issues_by_status
      unfiltered_issues_grouped = issues.map do |issue|
        next unless issue[:fieldValues][:nodes].any? do |field|
                      field[:name] && field[:field][:name] == 'Status' && field[:name] != 'New'
                    end

        [
          issue[:content].to_h,
          issue[:fieldValues][:nodes].find do |field|
            field[:name] && field[:field][:name] == 'Status' && field[:name] != 'New'
          end&.[](:name)
        ]
      end.compact.to_h

      unfiltered_issues_grouped.keys.group_by { |status| unfiltered_issues_grouped.to_h[status] }
    end

    def issue_ids_by_status
      issue_ids_by_status = {}

      issues_by_status.each do |status, issues|
        issue_ids_by_status[status] = issues.map { |issue| issue[:number] }
      end

      issue_ids_by_status
    end

    def issue_ids_for_column(column_name)
      issues.map do |node|
        issue_column_name = node[:fieldValues][:nodes].find do |field|
                              field[:field][:name] == 'Status'
        rescue StandardError
          nil
                            end&.[](:name)
        node[:id] if issue_column_name == column_name
      end.compact
    end

    def issue_ids(exclude_closed: false)
      if exclude_closed
        issues.map { |node| node[:id] if node[:content][:state] == 'OPEN' }.compact
      else
        issues.map { |node| node[:id] }
      end
    end

    def issues
      @issues ||= begin
        puts 'Loading GitHub Project...'
        items = []
        has_next_page = true
        cursor = nil

        while has_next_page
          response = query(build_query(cursor))
          project_items = response.dig(:data, :node, :items, :nodes)
          items.concat(project_items)

          page_info = response.dig(:data, :node, :items, :pageInfo)
          has_next_page = page_info[:hasNextPage]
          cursor = page_info[:endCursor]
        end

        items
      end
    end

    def build_query(cursor = nil)
      after_cursor = cursor ? %(, after: "#{cursor}") : ''
      %{
        query {
          node(id: "#{node_id}") {
            ... on ProjectV2 {
              items(first: 100#{after_cursor}) {
                nodes {
                  id
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldTextValue {
                        text
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                      ... on ProjectV2ItemFieldNumberValue {
                        number
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                      ... on ProjectV2ItemFieldDateValue {
                        date
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        name
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                    }
                  }
                  content {
                    ... on DraftIssue {
                      title
                      body
                    }
                    ... on Issue {
                      title
                      number
                      state
                      assignees(first: 10) {
                        nodes {
                          login
                        }
                      }
                    }
                    ... on PullRequest {
                      title
                      number
                      state
                      assignees(first: 10) {
                        nodes {
                          login
                        }
                      }
                    }
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }
            }
          }
        }
      }
    end

    def node_id
      @node_id ||= query(
        %{query{organization(login: "#{organization}") {projectV2(number: #{number}){id}}}}
      )[:data][:organization][:projectV2][:id]
    end

    def query(query)
      response = client.post '/graphql', { query: }.to_json
      p response if ENV['DEBUG']
      if response[:errors]
        puts "Query: #{query}"
        puts(response[:errors].map { |error| error[:message] })
        raise 'GraphQL Error'
      end
      response
    end

    def client
      @client = Octokit::Client.new access_token: token
    end
  end
end
