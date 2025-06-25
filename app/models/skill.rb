class Skill < ApplicationRecord
  belongs_to :resume
  validates :name, presence: true

  after_save :log_save
  after_create :log_create

  private

  def log_save
    Rails.logger.info "Skill saved: #{name} (ID: #{id})"
  end

  def log_create
    Rails.logger.info "Skill created: #{name} (ID: #{id})"
  end
end
