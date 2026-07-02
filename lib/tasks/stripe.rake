# frozen_string_literal: true

namespace :stripe do
  desc "Verify Stripe configuration (run from project root)"
  task check: :environment do
    puts "\nStripe configuration check:"
    puts "  STRIPE_PUBLISHABLE_KEY: #{ENV["STRIPE_PUBLISHABLE_KEY"].present? ? "✓ set" : "✗ missing"}"
    puts "  STRIPE_SECRET_KEY: #{ENV["STRIPE_SECRET_KEY"].present? ? "✓ set" : "✗ missing"}"
    puts "  STRIPE_PRICE_GROWTH_ID: #{ENV["STRIPE_PRICE_GROWTH_ID"].presence || "✗ missing"}"
    puts "  STRIPE_PRICE_PRO_ID: #{ENV["STRIPE_PRICE_PRO_ID"].presence || "✗ missing"}"
    puts "  STRIPE_PRICE_COVER_LETTER_ID: #{ENV["STRIPE_PRICE_COVER_LETTER_ID"].presence || "✗ missing"}"
    puts "  STRIPE_PRICE_JOB_SEARCH_PASS_ID: #{ENV["STRIPE_PRICE_JOB_SEARCH_PASS_ID"].presence || "✗ missing"}"
    puts "  STRIPE_PRICE_LIFETIME_ID: #{ENV["STRIPE_PRICE_LIFETIME_ID"].presence || "✗ missing"}"
    puts "  STRIPE_WEBHOOK_SECRET: #{ENV["STRIPE_WEBHOOK_SECRET"].present? ? "✓ set" : "✗ missing (optional for checkout)"}"
    puts "\n.env exists: #{File.exist?(Rails.root.join(".env"))}"
    puts "Rails.env: #{Rails.env}"
    puts ""
  end
end
