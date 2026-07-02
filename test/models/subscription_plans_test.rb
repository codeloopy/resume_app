# frozen_string_literal: true

require "test_helper"

class SubscriptionPlansTest < ActiveSupport::TestCase
  test "resume limits by tier" do
    assert_equal 1, SubscriptionPlans.resume_limit_for("free")
    assert_equal 2, SubscriptionPlans.resume_limit_for("growth")
    assert_equal 10, SubscriptionPlans.resume_limit_for("pro")
  end

  test "jd scan limits" do
    assert_equal 3, SubscriptionPlans.jd_scan_limit_for("free")
    assert_equal 15, SubscriptionPlans.jd_scan_limit_for("growth")
    assert_nil SubscriptionPlans.jd_scan_limit_for("pro")
  end

  test "ai credit costs" do
    assert_equal 3, SubscriptionPlans::AI_CREDIT_COSTS[:cover_letter]
  end
end
