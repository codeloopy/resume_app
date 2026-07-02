# frozen_string_literal: true

class UserEntitlements
  def initialize(user)
    @user = user
  end

  def premium?
    @user.growth? || pro_features? || job_search_pass_active?
  end

  def pro_features?
    @user.admin? || @user.subscription_tier == "pro" || lifetime_access?
  end

  def lifetime_access?
    @user.read_attribute(:lifetime_access) == true
  end

  def job_search_pass_active?
    expires_at = @user.job_search_pass_expires_at
    expires_at.present? && expires_at > Time.current
  end

  def cover_letter_access?
    premium? || @user.cover_letter_purchased?
  end

  def job_application_access?
    pro_features? || job_search_pass_active?
  end

  def deep_ats_analysis?
    premium?
  end

  def resume_limit
    return SubscriptionPlans::RESUME_LIMITS["pro"] if @user.admin?
    return SubscriptionPlans::PASS_RESUME_LIMIT if job_search_pass_active?
    return SubscriptionPlans::RESUME_LIMITS["pro"] if pro_features?

    SubscriptionPlans.resume_limit_for(effective_tier)
  end

  def jd_scan_limit
    return nil if pro_features? || job_search_pass_active?

    SubscriptionPlans.jd_scan_limit_for(effective_tier)
  end

  def ai_credit_limit
    return nil if pro_features?
    return SubscriptionPlans::PASS_AI_CREDIT_LIMIT if job_search_pass_active?

    SubscriptionPlans.ai_credit_limit_for(effective_tier)
  end

  def effective_tier
    return "pro" if pro_features?
    return "growth" if @user.growth? || job_search_pass_active?

    "free"
  end

  private

  attr_reader :user
end
