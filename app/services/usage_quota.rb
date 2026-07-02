# frozen_string_literal: true

# Tracks and enforces monthly usage quotas for JD scans and AI credits.
class UsageQuota
  class LimitExceeded < StandardError
    attr_reader :quota_type

    def initialize(quota_type)
      @quota_type = quota_type
      super("#{quota_type.to_s.humanize} limit reached for this month")
    end
  end

  def initialize(user)
    @user = user
    @entitlements = user.entitlements
  end

  def jd_scans_remaining
    limit = @entitlements.jd_scan_limit
    return Float::INFINITY if limit.nil?

    [ limit - current_jd_scans_used, 0 ].max
  end

  def can_scan_job_description?
    jd_scans_remaining.positive? || jd_scans_remaining.infinite?
  end

  def consume_jd_scan!
    reset_jd_period_if_needed!
    limit = @entitlements.jd_scan_limit
    return true if limit.nil?

    raise LimitExceeded, :jd_scan if current_jd_scans_used >= limit

    @user.increment!(:jd_scans_used)
    true
  end

  def ai_credits_remaining
    limit = @entitlements.ai_credit_limit
    return Float::INFINITY if limit.nil?

    [ limit - current_ai_credits_used, 0 ].max
  end

  def can_spend_ai_credits?(amount)
    remaining = ai_credits_remaining
    return true if remaining.infinite?

    remaining >= amount
  end

  def spend_ai_credits!(amount)
    reset_ai_period_if_needed!
    raise ArgumentError, "amount must be positive" unless amount.positive?

    limit = @entitlements.ai_credit_limit
    return true if limit.nil?

    raise LimitExceeded, :ai_credit unless can_spend_ai_credits?(amount)

    @user.increment!(:ai_credits_used, amount)
    true
  end

  private

  def current_jd_scans_used
    reset_jd_period_if_needed!
    @user.jd_scans_used
  end

  def current_ai_credits_used
    reset_ai_period_if_needed!
    @user.ai_credits_used
  end

  def reset_jd_period_if_needed!
    return if @user.jd_scans_period_start == Date.current.beginning_of_month

    @user.update!(jd_scans_used: 0, jd_scans_period_start: Date.current.beginning_of_month)
  end

  def reset_ai_period_if_needed!
    return if @user.ai_credits_period_start == Date.current.beginning_of_month

    @user.update!(ai_credits_used: 0, ai_credits_period_start: Date.current.beginning_of_month)
  end
end
