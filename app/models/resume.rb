class Resume < ApplicationRecord
  belongs_to :user
  has_rich_text :summary
  validates :slug, presence: true, uniqueness: true
  before_validation :generate_slug, on: :create
  before_validation :ensure_slug_present

  has_many :experiences, dependent: :destroy
  accepts_nested_attributes_for :experiences, allow_destroy: true

  has_many :skills, dependent: :destroy
  accepts_nested_attributes_for :skills, allow_destroy: true

  has_many :educations, dependent: :destroy
  accepts_nested_attributes_for :educations, allow_destroy: true

  has_many :projects, dependent: :destroy
  accepts_nested_attributes_for :projects, allow_destroy: true

  delegate :first_name, :last_name, :email, :phone, :linked_in_url, :github_url, :portfolio, :location, to: :user, prefix: true

  def to_param
    slug
  end

  def pdf_template
    super.presence || "modern"
  end

  def regenerate_slug!
    self.slug = nil
    generate_slug
    save!
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = "#{user.first_name.parameterize}-#{user.last_name.parameterize}"
    random_suffix = SecureRandom.hex(4) # Always use 4 characters for consistency
    self.slug = "#{base_slug}-#{random_suffix}"
  end

  def ensure_slug_present
    generate_slug if slug.blank?
  end
end
