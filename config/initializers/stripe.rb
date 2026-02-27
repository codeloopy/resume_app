# frozen_string_literal: true

Rails.configuration.stripe = {
  publishable_key: ENV.fetch("STRIPE_PUBLISHABLE_KEY", ""),
  secret_key: ENV.fetch("STRIPE_SECRET_KEY", ""),
  webhook_secret: ENV.fetch("STRIPE_WEBHOOK_SECRET", "")
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
