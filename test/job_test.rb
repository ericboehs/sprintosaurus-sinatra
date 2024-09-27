# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require './environment'
require './job'

require 'minitest/autorun'
require 'mocha/minitest'

class JobTest < Minitest::Test
  def setup
    # Setup any necessary test data or mocks
  end

  def test_handle_rate_limit
    response = mock
    response.stubs(:headers).returns({
      'x-ratelimit-remaining' => '5',
      'x-ratelimit-reset' => (Time.now + 60).to_i.to_s,
      'x-ratelimit-limit' => '100'
    })

    Job.expects(:sleep).with(60)
    Job.handle_rate_limit(response)
  end

  def test_persist_issues
    project_info = {
      number: 1,
      title: 'Test Project',
      public: true,
      closed: false,
      url: 'https://github.com/orgs/test/projects/1'
    }

    sprints = [
      {
        iteration_id: 'IT_1',
        title: 'Sprint 1',
        start_date: Date.today,
        duration: 14
      }
    ]

    issues = [
      {
        content: {
          number: 1,
          title: 'Test Issue',
          state: 'OPEN',
          url: 'https://github.com/test/repo/issues/1',
          createdAt: Time.now,
          closedAt: nil
        },
        fieldValues: {
          nodes: [
            { field: { name: 'Sprint' }, iterationId: 'IT_1' },
            { field: { name: 'Points' }, number: 5 }
          ]
        }
      }
    ]

    mock_project = mock('Project')
    Project.expects(:find_or_initialize_by).with(number: 1).returns(mock_project)
    mock_project.expects(:title=).with('Test Project')
    mock_project.expects(:number=).with(1)
    mock_project.expects(:public=).with(true)
    mock_project.expects(:closed=).with(false)
    mock_project.expects(:url=).with('https://github.com/orgs/test/projects/1')
    mock_project.expects(:save)
    mock_project.expects(:id).returns(1)

    mock_sprint = mock('Sprint')
    Sprint.expects(:find_or_initialize_by).with(iteration_id: 'IT_1').returns(mock_sprint)
    mock_sprint.expects(:assign_attributes).with(
      title: 'Sprint 1',
      start_date: Date.today,
      duration: 14,
      project_id: 1
    )
    mock_sprint.expects(:save)
    mock_sprint.expects(:iteration_id).returns('IT_1')

    mock_issue = mock('Issue')
    Issue.expects(:find_or_initialize_by).with(number: 1).returns(mock_issue)
    mock_issue.expects(:title=).with('Test Issue')
    mock_issue.expects(:issues_sprints).returns([])
    mock_issue.expects(:points=).with(5)
    mock_issue.expects(:status=)
    mock_issue.expects(:state=).with('OPEN')
    mock_issue.expects(:url=).with('https://github.com/test/repo/issues/1')
    mock_issue.expects(:data=)
    mock_issue.expects(:closed_at=).with(nil)
    mock_issue.expects(:created_at=)
    mock_issue.expects(:save)

    mock_issue_sprint = mock('IssuesSprint')
    IssuesSprint.expects(:with_removed).returns(IssuesSprint)
    IssuesSprint.expects(:new).with(issue: mock_issue, sprint: mock_sprint).returns(mock_issue_sprint)
    mock_issue_sprint.expects(:created_at=)
    mock_issue_sprint.expects(:save)

    mock_sprint.expects(:iteration_id).returns('IT_1').twice

    Job.persist_issues(project_info, sprints, issues)
  end

  def test_run
    ENV['SEED_GH_PROJECT_URLS'] = 'https://github.com/orgs/test/projects/1'
    Project.expects(:all).returns([]).once
    Project.expects(:create).with(number: '1', url: 'https://github.com/orgs/test/projects/1')

    mock_project = mock('Project')
    Project.expects(:all).returns([mock_project]).once
    mock_project.expects(:url).returns('https://github.com/orgs/test/projects/1')

    mock_github_project = mock('Github::Project')
    Github::Project.expects(:new).with(token: ENV.fetch('GH_TOKEN'), organization: 'test', number: '1').returns(mock_github_project)
    
    mock_response = mock('Response')
    mock_github_project.expects(:build_query).returns('query')
    mock_github_project.expects(:query).with('query').returns(mock_response)
    Job.expects(:handle_rate_limit).with(mock_response)

    mock_github_project.expects(:info).returns({})
    mock_github_project.expects(:active_sprints).returns([])
    mock_github_project.expects(:issues).returns([])

    Job.expects(:persist_issues).with({}, [], [])

    Job.run
  end
end
