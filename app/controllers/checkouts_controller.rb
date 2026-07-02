# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  ONE_TIME_PLANS = %w[cover_letter job_search_pass lifetime].freeze
  SUBSCRIPTION_PLANS = %w[growth pro].freeze
  VALID_PLANS = (ONE_TIME_PLANS + SUBSCRIPTION_PLANS).freeze

  def create
    plan = params[:plan].to_s.strip.downcase
    price_id = price_id_for_plan(plan)

    unless price_id.present?
      if VALID_PLANS.include?(plan)
        msg = if Rails.env.production?
          "Stripe price IDs not set. Configure STRIPE_PRICE_* env vars for this plan."
        else
          "Stripe not configured. Ensure .env has the required price IDs, then restart the server (run: spring stop)."
        end
        redirect_to pricing_path, alert: msg
      else
        redirect_to pricing_path, alert: "Invalid plan selected."
      end
      return
    end

    session = create_checkout_session(price_id, plan)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe checkout error: #{e.message}"
    redirect_to pricing_path, alert: "Unable to start checkout. Please try again."
  end

  def success
    notice = case params[:purchase]
    when "cover_letter" then "Thank you! Cover letter access is now active."
    when "job_search_pass" then "Thank you! Your 90-day Job Search Pass is now active."
    when "lifetime" then "Thank you! Lifetime access is now active."
    else "Thank you! Your subscription is now active."
    end
    redirect_to resume_path, notice: notice
  end

  def cancel
    redirect_to pricing_path, notice: "Checkout was cancelled."
  end

  private

  def price_id_for_plan(plan)
    key = {
      "growth" => :price_growth_id,
      "pro" => :price_pro_id,
      "cover_letter" => :price_cover_letter_id,
      "job_search_pass" => :price_job_search_pass_id,
      "lifetime" => :price_lifetime_id
    }[plan]

    return nil unless key

    stripe_price_id(key)
  end

  def stripe_price_id(key)
    env_keys = {
      price_growth_id: "STRIPE_PRICE_GROWTH_ID",
      price_pro_id: "STRIPE_PRICE_PRO_ID",
      price_cover_letter_id: "STRIPE_PRICE_COVER_LETTER_ID",
      price_job_search_pass_id: "STRIPE_PRICE_JOB_SEARCH_PASS_ID",
      price_lifetime_id: "STRIPE_PRICE_LIFETIME_ID"
    }
    env_key = env_keys[key]
    Rails.configuration.stripe[key].presence || (env_key && ENV[env_key].presence)
  end

  def create_checkout_session(price_id, plan)
    customer_id = current_user.stripe_customer_id

    if ONE_TIME_PLANS.include?(plan)
      session_params = {
        mode: "payment",
        line_items: [ { price: price_id, quantity: 1 } ],
        success_url: "#{success_checkout_url}?purchase=#{plan}",
        cancel_url: cancel_checkout_url,
        metadata: {
          user_id: current_user.id,
          plan: plan
        }
      }
    else
      session_params = {
        mode: "subscription",
        line_items: [ { price: price_id, quantity: 1 } ],
        success_url: success_checkout_url,
        cancel_url: cancel_checkout_url,
        metadata: {
          user_id: current_user.id,
          plan: plan
        },
        subscription_data: {
          metadata: { user_id: current_user.id.to_s, plan: plan }
        }
      }
    end

    session_params[:customer] = customer_id if customer_id.present?
    session_params[:customer_email] = current_user.email if customer_id.blank?

    Stripe::Checkout::Session.create(session_params)
  end

  def reject_guest_user
    return unless current_user.guest?

    redirect_to upgrade_guest_user_form_path, alert: "Please create an account first to subscribe."
  end
end
