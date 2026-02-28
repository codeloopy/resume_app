class Resume < ApplicationRecord
  FREE_TEMPLATES = %w[modern classic].freeze
  PREMIUM_TEMPLATES = %w[minimal creative executive].freeze
  ALL_TEMPLATES = (FREE_TEMPLATES + PREMIUM_TEMPLATES).freeze

  belongs_to :user
  has_rich_text :summary
  validates :slug, presence: true, uniqueness: true
  before_validation :generate_slug, on: :create
  before_validation :ensure_slug_present
  before_validation :enforce_premium_template_access
  before_destroy :clear_user_current_resume

  has_many :experiences, dependent: :destroy
  accepts_nested_attributes_for :experiences, allow_destroy: true

  has_many :skills, dependent: :destroy
  accepts_nested_attributes_for :skills, allow_destroy: true

  has_many :educations, dependent: :destroy
  accepts_nested_attributes_for :educations, allow_destroy: true

  has_many :projects, dependent: :destroy
  accepts_nested_attributes_for :projects, allow_destroy: true

  has_many :resume_events, dependent: :destroy

  delegate :first_name, :last_name, :email, :phone, :linked_in_url, :github_url, :portfolio, :location, to: :user, prefix: true

  def to_param
    slug
  end

  def pdf_template
    template = super.presence || "modern"
    # Fallback to modern if user doesn't have access to premium template
    if PREMIUM_TEMPLATES.include?(template) && !user.pro? && !user.growth?
      "modern"
    else
      template
    end
  end

  def premium_template?
    PREMIUM_TEMPLATES.include?(pdf_template)
  end

  def has_content?
    summary.present? ||
    title.present? ||
    skills.any? ||
    experiences.any? ||
    educations.any? ||
    projects.any?
  end

  def ats_analysis
    return @ats_analysis if defined?(@ats_analysis)

    @ats_analysis = ::AtsAnalyzerService.new(self).analyze
  end

  def analytics_summary(since: 30.days.ago)
    {
      total_views: resume_events.views.count,
      total_downloads: resume_events.downloads.count,
      views_since: resume_events.views.since(since).count,
      downloads_since: resume_events.downloads.since(since).count,
      views_by_day: resume_events.views.since(since).group("DATE(created_at)").count,
      downloads_by_day: resume_events.downloads.since(since).group("DATE(created_at)").count
    }
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

  def enforce_premium_template_access
    return if user.pro? || user.growth?

    raw_template = read_attribute(:pdf_template)
    self.pdf_template = "modern" if raw_template.present? && PREMIUM_TEMPLATES.include?(raw_template)
  end

  def clear_user_current_resume
    User.where(current_resume_id: id).update_all(current_resume_id: nil)
  end
end
