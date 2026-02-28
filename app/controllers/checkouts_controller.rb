# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  def create
    plan = params[:plan].to_s.strip.downcase
    price_id = price_id_for_plan(plan)

    unless price_id.present?
      if %w[growth pro cover_letter].include?(plan)
        msg = if Rails.env.production?
          "Stripe price IDs not set. Run: fly secrets set STRIPE_PRICE_GROWTH_ID=price_xxx STRIPE_PRICE_PRO_ID=price_xxx STRIPE_PRICE_COVER_LETTER_ID=price_xxx"
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
    notice = params[:purchase] == "cover_letter" ? "Thank you! Cover letter access is now active." : "Thank you! Your subscription is now active."
    redirect_to resume_path, notice: notice
  end

  def cancel
    redirect_to pricing_path, notice: "Checkout was cancelled."
  end

  private

  def price_id_for_plan(plan)
    case plan
    when "growth" then stripe_price_id(:price_growth_id)
    when "pro" then stripe_price_id(:price_pro_id)
    when "cover_letter" then stripe_price_id(:price_cover_letter_id)
    else nil
    end
  end

  def stripe_price_id(key)
    env_keys = {
      price_growth_id: "STRIPE_PRICE_GROWTH_ID",
      price_pro_id: "STRIPE_PRICE_PRO_ID",
      price_cover_letter_id: "STRIPE_PRICE_COVER_LETTER_ID"
    }
    env_key = env_keys[key]
    Rails.configuration.stripe[key].presence || (env_key && ENV[env_key].presence)
  end

  def create_checkout_session(price_id, plan)
    customer_id = current_user.stripe_customer_id

    if plan == "cover_letter"
      # One-time payment for cover letter access
      session_params = {
        mode: "payment",
        line_items: [{ price: price_id, quantity: 1 }],
        success_url: "#{success_checkout_url}?purchase=cover_letter",
        cancel_url: cancel_checkout_url,
        metadata: {
          user_id: current_user.id,
          plan: plan
        }
      }
      session_params[:customer] = customer_id if customer_id.present?
      session_params[:customer_email] = current_user.email if customer_id.blank?
    else
      # Subscription for Growth/Pro
      session_params = {
        mode: "subscription",
        line_items: [{ price: price_id, quantity: 1 }],
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
      session_params[:customer] = customer_id if customer_id.present?
      session_params[:customer_email] = current_user.email if customer_id.blank?
    end

    Stripe::Checkout::Session.create(session_params)
  end

  def reject_guest_user
    return unless current_user.guest?

    redirect_to upgrade_guest_user_form_path, alert: "Please create an account first to subscribe."
  end
end
