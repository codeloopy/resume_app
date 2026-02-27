# frozen_string_literal: true

class WebhooksController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = Rails.configuration.stripe[:webhook_secret]

    return head :bad_request if webhook_secret.blank?

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError
      return head :bad_request
    rescue Stripe::SignatureVerificationError
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    user_id = session.metadata&.user_id || session.subscription_data&.metadata&.user_id
    plan = session.metadata&.plan || session.subscription_data&.metadata&.plan

    return if user_id.blank?

    user = User.find_by(id: user_id)
    return unless user

    user.update!(
      stripe_customer_id: session.customer_id,
      stripe_subscription_id: session.subscription,
      subscription_tier: plan.to_s
    )
  end

  def handle_subscription_updated(subscription)
    user_id = subscription.metadata&.user_id
    return if user_id.blank?

    user = User.find_by(stripe_subscription_id: subscription.id)
    return unless user

    case subscription.status
    when "active", "trialing"
      plan = subscription.metadata&.plan || infer_plan_from_price(subscription)
      user.update!(subscription_tier: plan.to_s)
    when "canceled", "unpaid", "past_due"
      user.update!(subscription_tier: "free", stripe_subscription_id: nil)
    end
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_subscription_id: subscription.id)
    return unless user

    user.update!(subscription_tier: "free", stripe_subscription_id: nil)
  end

  def infer_plan_from_price(subscription)
    return "pro" if subscription.items&.data&.first.blank?

    price_id = subscription.items.data.first.price.id
    if price_id == ENV["STRIPE_PRICE_GROWTH_ID"]
      "growth"
    elsif price_id == ENV["STRIPE_PRICE_PRO_ID"]
      "pro"
    else
      "pro"
    end
  end
end
