# Issue Model
class Issue < ActiveRecord::Base
  belongs_to :project
  has_many :issues_sprints, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :sprints, through: :issues_sprints, dependent: :destroy

  def repo
    url.match(%r{github.com/([^/]+)/([^/]+)})&.captures&.last
  end

  def assignees
    data.dig('content', 'assignees', 'nodes')&.map { |node| node['login'] } || []
  end

  def labels
    data.dig('content', 'labels', 'nodes')&.map { |node| node['name'] } || []
  end

  def open?
    state == 'OPEN'
  end

  def closed?
    state == 'CLOSED'
  end

  def merged?
    state == 'MERGED'
  end

  def unplanned?(sprint)
    issue_sprint = issues_sprints.find_by(sprint:)
    issue_sprint.created_at > issue_sprint.sprint.start_date
  end

  def added_at(sprint)
    issues_sprints.find_by(sprint:).created_at
  end

  def added_at_creation?(sprint)
    added_at(sprint) == created_at
  end

  def added_or_created(sprint)
    added_at_creation?(sprint) ? 'created' : 'added'
  end
end
