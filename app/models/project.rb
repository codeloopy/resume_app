class Project < ApplicationRecord
  belongs_to :resume
  has_rich_text :description

  validates :title, presence: true
  validates :description, presence: true
end
