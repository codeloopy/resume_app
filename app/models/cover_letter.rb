# frozen_string_literal: true

class CoverLetter < ApplicationRecord
  belongs_to :resume
  has_rich_text :content

  validates :resume_id, presence: true

  delegate :user, to: :resume

  def display_title
    title.presence || company_name.presence || job_title.presence || "Untitled Cover Letter"
  end
end
