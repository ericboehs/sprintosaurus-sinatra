# frozen_string_literal: true

# Mimics acts_as_paranoid
module Removable
  extend ActiveSupport::Concern

  included do
    default_scope { where removed_at: nil }

    scope :with_removed, -> { unscope where: :removed_at }
    scope :only_removed, -> { with_removed.where.not removed_at: nil }
  end

  def remove
    update_column :removed_at, Time.current
  end

  def removed?
    removed_at.present?
  end

  def restore
    update_column :removed_at, nil
  end
end
