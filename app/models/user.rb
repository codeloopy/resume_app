class User < ApplicationRecord
  has_one :resume, dependent: :destroy
  has_many :feedbacks

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: true

  after_create :create_resume

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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
    guest_user.create_resume!(slug: "guest-#{random_token}")
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

  def create_resume
    build_resume.save
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
    subscription_tier == "pro"
  end

  def growth?
    subscription_tier == "growth"
  end

  def free?
    subscription_tier == "free" || subscription_tier.blank?
  end

  def premium?
    pro? || growth?
  end

  # Resume limits by tier (for future multi-resume support)
  RESUME_LIMITS = { "free" => 1, "growth" => 2, "pro" => 10 }.freeze

  def resume_limit
    RESUME_LIMITS[subscription_tier] || RESUME_LIMITS["free"]
  end

  def resume_count
    resume.present? ? 1 : 0
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
