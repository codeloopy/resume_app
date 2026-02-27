# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  def create
    plan = params[:plan]
    price_id = price_id_for_plan(plan)

    unless price_id.present?
      redirect_to pricing_path, alert: "Invalid plan selected."
      return
    end

    session = create_checkout_session(price_id, plan)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe checkout error: #{e.message}"
    redirect_to pricing_path, alert: "Unable to start checkout. Please try again."
  end

  def success
    redirect_to resume_path, notice: "Thank you! Your subscription is now active."
  end

  def cancel
    redirect_to pricing_path, notice: "Checkout was cancelled."
  end

  private

  def price_id_for_plan(plan)
    case plan.to_s
    when "growth" then ENV["STRIPE_PRICE_GROWTH_ID"]
    when "pro" then ENV["STRIPE_PRICE_PRO_ID"]
    else nil
    end
  end

  def create_checkout_session(price_id, plan)
    customer_id = current_user.stripe_customer_id

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

    Stripe::Checkout::Session.create(session_params)
  end

  def reject_guest_user
    return unless current_user.guest?

    redirect_to upgrade_guest_user_form_path, alert: "Please create an account first to subscribe."
  end
end
