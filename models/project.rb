# Project Model
class Project < ActiveRecord::Base
  has_many :sprints
  after_commit :run_job, on: :create

  def run_job
    Job.run [self]
  end
end
