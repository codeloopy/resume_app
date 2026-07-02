# frozen_string_literal: true

require "test_helper"

class JobDescriptionMatchServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "match@example.com",
      password: "password123",
      first_name: "Match",
      last_name: "Test"
    )
    @resume = @user.resume
    @resume.update!(title: "Software Engineer")
    @resume.skills.create!(name: "Ruby")
    @resume.skills.create!(name: "Rails")
    @resume.skills.create!(name: "PostgreSQL")
  end

  test "calculates match score from shared keywords" do
    job_description = "We need a Software Engineer with Ruby, Rails, PostgreSQL, and Redis experience."
    result = JobDescriptionMatchService.new(@resume, job_description: job_description).analyze

    assert result[:match_score].positive?
    assert_includes result[:matched_keywords], "ruby"
    assert_includes result[:matched_keywords], "rails"
    assert_includes result[:missing_keywords], "redis"
  end

  test "returns zero score for empty job description keywords" do
    result = JobDescriptionMatchService.new(@resume, job_description: "a an the").analyze

    assert_equal 0, result[:match_score]
  end
end
