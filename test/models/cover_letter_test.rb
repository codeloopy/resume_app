# frozen_string_literal: true

require "test_helper"

class CoverLetterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "cover_test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )
    @resume = @user.create_resume
  end

  test "belongs to resume" do
    cover_letter = @resume.cover_letters.create!(company_name: "Acme", job_title: "Engineer")
    assert_equal @resume, cover_letter.resume
    assert_equal @user, cover_letter.user
  end

  test "display_title returns title or company or job_title or default" do
    cl = @resume.cover_letters.build
    assert_equal "Untitled Cover Letter", cl.display_title

    cl.company_name = "Acme"
    assert_equal "Acme", cl.display_title

    cl.job_title = "Engineer"
    assert_equal "Acme", cl.display_title

    cl.title = "Custom"
    assert_equal "Custom", cl.display_title
  end
end
