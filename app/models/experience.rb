class Experience < ApplicationRecord
  belongs_to :resume
  validates :company_name, :title, :title, :start_date, presence: true
end
