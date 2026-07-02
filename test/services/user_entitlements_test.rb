# frozen_string_literal: true

require "test_helper"

class UserEntitlementsTest < ActiveSupport::TestCase
  def build_user(attrs = {})
    User.new({
      email: "test@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User",
      subscription_tier: "free"
    }.merge(attrs))
  end

  test "free user has limited access" do
    user = build_user
    entitlements = UserEntitlements.new(user)

    refute entitlements.premium?
    refute entitlements.cover_letter_access?
    refute entitlements.deep_ats_analysis?
    refute entitlements.job_application_access?
    assert_equal 1, entitlements.resume_limit
    assert_equal 3, entitlements.jd_scan_limit
  end

  test "cover letter purchased grants cover letter access" do
    user = build_user(cover_letter_purchased: true)
    entitlements = UserEntitlements.new(user)

    assert entitlements.cover_letter_access?
    refute entitlements.premium?
  end

  test "growth user has premium entitlements" do
    user = build_user(subscription_tier: "growth")
    entitlements = UserEntitlements.new(user)

    assert entitlements.premium?
    assert entitlements.cover_letter_access?
    assert entitlements.deep_ats_analysis?
    refute entitlements.job_application_access?
    assert_equal 2, entitlements.resume_limit
  end

  test "pro user has full access" do
    user = build_user(subscription_tier: "pro")
    entitlements = UserEntitlements.new(user)

    assert entitlements.pro_features?
    assert entitlements.job_application_access?
    assert_nil entitlements.jd_scan_limit
  end

  test "lifetime access grants pro features" do
    user = build_user(lifetime_access: true)
    entitlements = UserEntitlements.new(user)

    assert entitlements.lifetime_access?
    assert entitlements.pro_features?
    assert entitlements.job_application_access?
  end

  test "active job search pass grants pro-like access" do
    user = build_user(job_search_pass_expires_at: 30.days.from_now)
    entitlements = UserEntitlements.new(user)

    assert entitlements.job_search_pass_active?
    assert entitlements.premium?
    assert entitlements.cover_letter_access?
    assert entitlements.job_application_access?
    assert_equal 3, entitlements.resume_limit
  end

  test "expired job search pass does not grant access" do
    user = build_user(job_search_pass_expires_at: 1.day.ago)
    entitlements = UserEntitlements.new(user)

    refute entitlements.job_search_pass_active?
    refute entitlements.premium?
  end
end
