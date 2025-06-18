class Education < ApplicationRecord
  belongs_to :resume

  validates :school, presence: true
  validates :location, presence: true
  validates :field_of_study, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
end
