# Sprint Model
class Sprint < ActiveRecord::Base
  belongs_to :project
  has_many :issues_sprints, dependent: :destroy
  has_many :issues, -> { order issues_sprints: { created_at: :asc } }, dependent: :destroy, through: :issues_sprints do
    def open
      where state: 'OPEN'
    end

    def closed
      where state: 'CLOSED'
    end
  end

  def end_date
    start_date + duration.days - 1
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

  def ideal_points_remaining
    working_days_count = working_days(start_date, end_date)
    points_per_day = points.to_f / working_days_count
    points - (points_per_day * elapsed_days).round
  end

  def elapsed_days
    completed? ? duration : working_days(start_date, Date.today)
  end

  def off_track_by
    ((points_remaining - ideal_points_remaining).to_f / points * 100).round
  end

  def working_days(start_date, end_date)
    (start_date..end_date).count { |date| (1..5).include?(date.wday) }
  end
end
