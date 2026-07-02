# frozen_string_literal: true

require "test_helper"

class UsageQuotaTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "quota@example.com",
      password: "password123",
      first_name: "Quota",
      last_name: "User",
      subscription_tier: "free",
      jd_scans_period_start: Date.current.beginning_of_month,
      ai_credits_period_start: Date.current.beginning_of_month
    )
    @quota = UsageQuota.new(@user)
  end

  test "free user has limited jd scans" do
    assert_equal 3, @quota.jd_scans_remaining
    3.times { @quota.consume_jd_scan! }
    assert_equal 0, @quota.jd_scans_remaining
    assert_raises(UsageQuota::LimitExceeded) { @quota.consume_jd_scan! }
  end

  test "free user ai credits are enforced" do
    assert @quota.can_spend_ai_credits?(3)
    @quota.spend_ai_credits!(3)
    assert_equal 2, @quota.ai_credits_remaining
  end

  test "pro user has unlimited jd scans" do
    @user.update!(subscription_tier: "pro")
    quota = UsageQuota.new(@user.reload)

    10.times { quota.consume_jd_scan! }
    assert quota.jd_scans_remaining.infinite?
  end
end
