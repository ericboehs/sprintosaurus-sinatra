# Issue Model
class Issue < ActiveRecord::Base
  has_many :issues_sprints, -> { order(created_at: :desc) }
  has_many :sprints, through: :issues_sprints

  def repo
    url.match(%r{github.com/([^/]+)/([^/]+)})&.captures&.last
  end

  def open?
    state == 'OPEN'
  end

  def closed?
    state == 'CLOSED'
  end

  def unplanned?(sprint)
    issue_sprint = issues_sprints.find_by(sprint:)
    issue_sprint.created_at > issue_sprint.sprint.start_date &&
      created_at.to_date != issue_sprint.created_at.to_date
  end
end
