# frozen_string_literal: true

class ResumeEvent < ApplicationRecord
  EVENT_TYPES = %w[view download].freeze

  belongs_to :resume

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :views, -> { where(event_type: "view") }
  scope :downloads, -> { where(event_type: "download") }
  scope :since, ->(time) { where("created_at >= ?", time) }

  class << self
    def track!(resume:, event_type:)
      create!(resume: resume, event_type: event_type)
    end
  end
end
