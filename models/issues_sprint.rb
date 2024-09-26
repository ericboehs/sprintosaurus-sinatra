# Join model for Issue and Sprint
class IssuesSprint < ActiveRecord::Base
  include Removable

  belongs_to :issue
  belongs_to :sprint, touch: true
end
