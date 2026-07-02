class User < ApplicationRecord
  has_many :resumes, dependent: :destroy
  belongs_to :current_resume, class_name: "Resume", optional: true
  has_many :feedbacks

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true

  after_create :create_resume

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  def self.create_guest
    # Generate a unique email that won't conflict
    email = nil
    random_token = nil

    loop do
      random_token = SecureRandom.hex(10)
      email = "guest_#{random_token}@example.com"
      break unless User.exists?(email: email)
    end

    guest_user = User.create!(
      email: email,
      password: SecureRandom.hex(10),
      first_name: "Guest",
      last_name: "User",
      guest: true
    )
    guest_user.resume.update!(slug: "guest-#{random_token}")
    guest_user
  end

  def convert_to_regular_user(params)
    update!(
      email: params[:email],
      password: params[:password],
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone: params[:phone],
      location: params[:location],
      linked_in_url: params[:linked_in_url],
      github_url: params[:github_url],
      portfolio: params[:portfolio],
      guest: false
    )
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns the resume the user is currently editing (for backwards compatibility)
  def resume
    current_resume || resumes.first
  end

  def create_resume(slug: nil)
    new_resume = resumes.build(slug: slug)
    new_resume.save!
    update_column(:current_resume_id, new_resume.id)
    new_resume
  end

  def switch_resume!(resume)
    return unless resumes.include?(resume)

    update!(current_resume_id: resume.id)
  end

  def admin?
    role === "admin"
  end

  def user?
    role === "user"
  end

  def guest?
    guest == true
  end

  def pro?
    entitlements.pro_features? || job_search_pass_active?
  end

  def growth?
    subscription_tier == "growth"
  end

  def free?
    !admin? && (subscription_tier == "free" || subscription_tier.blank?) && !lifetime_access? && !job_search_pass_active?
  end

  def premium?
    entitlements.premium?
  end

  def entitlements
    @entitlements ||= UserEntitlements.new(self)
  end

  def usage_quota
    @usage_quota ||= UsageQuota.new(self)
  end

  def cover_letter_access?
    entitlements.cover_letter_access?
  end

  def job_application_access?
    entitlements.job_application_access?
  end

  def deep_ats_analysis?
    entitlements.deep_ats_analysis?
  end

  def job_search_pass_active?
    entitlements.job_search_pass_active?
  end

  def lifetime_access?
    entitlements.lifetime_access?
  end

  def resume_limit
    entitlements.resume_limit
  end

  def resume_count
    resumes.count
  end

  def at_resume_limit?
    resume_count >= resume_limit
  end

  # Class method to clean up old guest users (default: 24 hours)
  def self.cleanup_old_guests(cutoff_hours = 24)
    cutoff_time = cutoff_hours.hours.ago

    old_guests = where(guest: true)
                 .where("updated_at < ?", cutoff_time)

    count = old_guests.count

    if count > 0
      # Delete associated resumes first (due to dependent: :destroy)
      old_guests.each do |guest|
        guest.resume&.destroy if guest.resume
      end

      # Delete the guest users
      old_guests.destroy_all

      Rails.logger.info "Cleaned up #{count} old guest users older than #{cutoff_hours} hours"
    end

    count
  end

  private
end
