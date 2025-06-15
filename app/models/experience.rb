class Experience < ApplicationRecord
  belongs_to :resume
  has_many :responsibilities, dependent: :destroy

  validates :company_name, :title, :title, :start_date, presence: true
  accepts_nested_attributes_for :responsibilities, allow_destroy: true, reject_if: :all_blank
end
