# frozen_string_literal: true

require "test_helper"

class JobMatchScanTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "scan@example.com",
      password: "password123",
      first_name: "Scan",
      last_name: "User"
    )
    @resume = @user.resume
  end

  test "display_title uses company and job title" do
    scan = @resume.job_match_scans.create!(
      company_name: "Acme",
      job_title: "Engineer",
      job_description: "Ruby developer needed",
      match_score: 80,
      result: {}
    )

    assert_equal "Acme — Engineer", scan.display_title
  end
end
