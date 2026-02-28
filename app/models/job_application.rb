# frozen_string_literal: true

class JobApplication < ApplicationRecord
  belongs_to :resume

  STATUSES = %w[draft applied screening interview offer rejected withdrawn].freeze

  validates :company, presence: true
  validates :role, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent_first, -> { order(applied_at: :desc, updated_at: :desc) }

  def display_title
    [ company, role ].compact.join(" — ")
  end

  def status_label
    status&.titleize
  end
end
