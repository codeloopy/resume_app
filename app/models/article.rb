class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  validates :title, presence: true
  validates :body, presence: true
  validates :category, presence: true
  validates :author, presence: true
  validates :author_initials, presence: true
  validates :published_at, presence: true

  before_validation :set_color_and_icon
  has_rich_text :body

  scope :published, -> { where("published_at <= ?", Time.current) }

  private

  def set_color_and_icon
    return if category.blank?
    options = article_category_color_and_icon(self.category)
    self.color = options[:color]
    self.icon = options[:icon]
  end

  def article_category_color_and_icon(category)
    case category
    when "Interview Prep"
      { color: "blue", icon: "handshake" }
    when "Career Growth"
      { color: "green", icon: "chart-line" }
    when "Job Search"
      { color: "purple", icon: "search" }
    when "Resume Tips"
      { color: "yellow", icon: "lightbulb" }
    when "Career Change"
      { color: "indigo", icon: "briefcase" }
    when "Networking"
      { color: "red", icon: "network-wired" }
    else
      { color: "gray", icon: "smile" }
    end
  end
end
