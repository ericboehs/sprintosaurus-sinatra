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
end
