# frozen_string_literal: true

class JobMatchScan < ApplicationRecord
  belongs_to :resume

  validates :job_description, presence: true
  validates :match_score, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :recent_first, -> { order(created_at: :desc) }

  def display_title
    [ company_name, job_title ].compact.join(" — ").presence || "Job Match Scan"
  end
end
