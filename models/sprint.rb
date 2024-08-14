# Sprint Model
class Sprint < ActiveRecord::Base
  has_many :issues_sprints
  has_many :issues, through: :issues_sprints do
    def open
      where state: 'OPEN'
    end

    def closed
      where state: 'CLOSED'
    end
  end

  def end_date
    start_date + duration.days
  end

  def completed?
    end_date < Date.today
  end

  def in_progress?
    start_date <= Date.today && end_date >= Date.today
  end

  def planned?
    start_date > Date.today
  end

  def points
    issues.sum(:points)
  end

  def points_remaining
    issues.open.sum(:points)
  end

  def points_completed
    issues.closed.sum(:points)
  end
end
