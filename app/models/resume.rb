class Resume < ApplicationRecord
  belongs_to :user
  has_rich_text :summary

  has_many :experiences, dependent: :destroy
  accepts_nested_attributes_for :experiences, allow_destroy: true

  has_many :skills, dependent: :destroy
  accepts_nested_attributes_for :skills, allow_destroy: true

  has_many :educations, dependent: :destroy
  accepts_nested_attributes_for :educations, allow_destroy: true

  has_many :projects, dependent: :destroy
  accepts_nested_attributes_for :projects, allow_destroy: true

  has_many :references, dependent: :destroy
  accepts_nested_attributes_for :references, allow_destroy: true

  has_many :skills, dependent: :destroy
  accepts_nested_attributes_for :skills, allow_destroy: true

  has_many :education, dependent: :destroy
  accepts_nested_attributes_for :education, allow_destroy: true

  has_many :projects, dependent: :destroy
  accepts_nested_attributes_for :projects, allow_destroy: true

  delegate :first_name, :last_name, :email, :phone, :linked_in_url, :github_url, :portfolio, to: :user, prefix: true
end
