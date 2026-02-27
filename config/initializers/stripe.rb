# frozen_string_literal: true

# Reload .env in development if price IDs are missing (handles Spring/caching)
if Rails.env.development? &&
   ENV["STRIPE_PRICE_GROWTH_ID"].blank? &&
   File.exist?(Rails.root.join(".env"))
  begin
    require "dotenv"
    Dotenv.load(Rails.root.join(".env"))
  rescue LoadError
    # dotenv not available
  end
end

Rails.configuration.stripe = {
  publishable_key: ENV.fetch("STRIPE_PUBLISHABLE_KEY", ""),
  secret_key: ENV.fetch("STRIPE_SECRET_KEY", ""),
  webhook_secret: ENV.fetch("STRIPE_WEBHOOK_SECRET", ""),
  price_growth_id: ENV.fetch("STRIPE_PRICE_GROWTH_ID", ""),
  price_pro_id: ENV.fetch("STRIPE_PRICE_PRO_ID", "")
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
