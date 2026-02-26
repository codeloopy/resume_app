# frozen_string_literal: true

class GuestActivity < ApplicationRecord
  EVENT_TYPES = %w[
    signup
    wizard_step_completed
    wizard_completed
    pdf_view
    public_resume_view
    converted
  ].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :signups, -> { where(event_type: "signup") }
  scope :wizard_step_completions, -> { where(event_type: "wizard_step_completed") }
  scope :wizard_completions, -> { where(event_type: "wizard_completed") }
  scope :pdf_views, -> { where(event_type: "pdf_view") }
  scope :public_resume_views, -> { where(event_type: "public_resume_view") }
  scope :conversions, -> { where(event_type: "converted") }

  scope :since, ->(time) { where("created_at >= ?", time) }
  scope :today, -> { since(Time.current.beginning_of_day) }
  scope :last_7_days, -> { since(7.days.ago) }

  class << self
    def track!(event_type:, guest_user: nil, session_id: nil, metadata: {})
      create!(
        event_type: event_type,
        guest_user_id: guest_user&.id,
        session_id: session_id,
        metadata: metadata
      )
    end

    def stats_for_period(since_time)
      {
        signups: signups.since(since_time).count,
        wizard_completions: wizard_completions.since(since_time).count,
        pdf_views: pdf_views.since(since_time).count,
        public_resume_views: public_resume_views.since(since_time).count,
        conversions: conversions.since(since_time).count
      }
    end

    def conversion_rate(since_time)
      signups_count = signups.since(since_time).count
      return 0.0 if signups_count.zero?

      (conversions.since(since_time).count.to_f / signups_count * 100).round(1)
    end
  end
end
