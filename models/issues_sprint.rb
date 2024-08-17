# Join model for Issue and Sprint
class IssuesSprint < ActiveRecord::Base
  belongs_to :issue
  belongs_to :sprint, touch: true
end
