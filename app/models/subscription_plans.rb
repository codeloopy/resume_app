# frozen_string_literal: true

# Central configuration for subscription tiers, usage limits, and AI credit costs.
module SubscriptionPlans
  TIERS = %w[free growth pro].freeze

  ONE_TIME_PLANS = %w[cover_letter job_search_pass lifetime].freeze

  RESUME_LIMITS = {
    "free" => 1,
    "growth" => 2,
    "pro" => 10
  }.freeze

  PASS_RESUME_LIMIT = 3

  # Job-description match scans per calendar month
  JD_SCAN_LIMITS = {
    "free" => 3,
    "growth" => 15,
    "pro" => nil # unlimited
  }.freeze

  PASS_JD_SCAN_LIMIT = nil # unlimited during active pass

  # AI credits allocated per calendar month (nil = unlimited)
  AI_CREDIT_LIMITS = {
    "free" => 5,
    "growth" => 50,
    "pro" => 200
  }.freeze

  PASS_AI_CREDIT_LIMIT = 200

  AI_CREDIT_COSTS = {
    cover_letter: 3,
    bullet_rewrite: 1,
    job_match_detail: 1
  }.freeze

  JOB_SEARCH_PASS_DURATION = 90.days

  def self.resume_limit_for(tier)
    RESUME_LIMITS.fetch(tier.to_s, RESUME_LIMITS["free"])
  end

  def self.jd_scan_limit_for(tier)
    JD_SCAN_LIMITS.fetch(tier.to_s, JD_SCAN_LIMITS["free"])
  end

  def self.ai_credit_limit_for(tier)
    AI_CREDIT_LIMITS.fetch(tier.to_s, AI_CREDIT_LIMITS["free"])
  end
end
