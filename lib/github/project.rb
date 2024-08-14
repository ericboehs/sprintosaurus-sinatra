require 'octokit'

module Github
  # Class to interact with GitHub Projects
  class Project
    attr_accessor :token, :organization, :repo, :number

    def initialize(token:, organization:, repo:, number:)
      @token = token
      @organization = organization
      @repo = repo
      @number = number
    end

    def snapshot_board
      puts JSON.pretty_generate sprints_with_issues
    end

    def sprints_with_issues
      sprints.map { |sprint| [sprint[:title], issues_by_sprint(sprint[:title])] }.to_h
    end

    def sprints
      issues.map do |issue|
        issue[:fieldValues][:nodes].select { |node| node[:field] && node[:field][:name] == 'Sprint' }
      end.flatten.uniq
    end

    def issues_by_sprint(sprint_title)
      sprint_issues = []

      issues.each do |issue|
        issue[:fieldValues][:nodes].each do |node|
          if node[:field] && node[:field][:name] == "Sprint"
            next unless node[:title] == sprint_title

            sprint_issues << issue.to_h
          end
        end
      end

      sprint_issues
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
                      ... on ProjectV2ItemFieldIterationValue {
                        title
                        iterationId
                        startDate
                        duration
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
