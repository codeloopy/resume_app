class User < ApplicationRecord
  has_one :resume, dependent: :destroy
  has_many :feedbacks

  after_create :create_resume

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def create_resume
    build_resume.save
  end
end
