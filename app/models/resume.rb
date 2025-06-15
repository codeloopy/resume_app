class Resume < ApplicationRecord
  belongs_to :user
  has_rich_text :summary

  has_many :experiences, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :educations, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :awards, dependent: :destroy
  has_many :references, dependent: :destroy

  delegate :first_name, :last_name, :email, :phone, :linked_in_url, :github_url, :portfolio, to: :user, prefix: true
end
