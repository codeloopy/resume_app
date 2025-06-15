class Responsibility < ApplicationRecord
  belongs_to :experience

  validates :content, presence: true
end
