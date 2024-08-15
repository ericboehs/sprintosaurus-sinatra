# Sprint Model
class Sprint < ActiveRecord::Base
  belongs_to :project
  has_many :issues_sprints
  has_many :issues, -> { order issues_sprints: { created_at: :asc } }, through: :issues_sprints do
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

  def off_track_by
    elapsed_days = (Date.today - start_date).to_i
    expected_completion = (elapsed_days.to_f / duration * 100).round
    actual_completion = ((points_completed.to_f / points) * 100).round
    (actual_completion - expected_completion).abs
  end
end
