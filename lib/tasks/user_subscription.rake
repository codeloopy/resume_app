# frozen_string_literal: true

namespace :user do
  desc "Set user to Growth tier: rails user:set_growth EMAIL=user@example.com"
  task set_growth: :environment do
    email = ENV["EMAIL"]
    if email.blank?
      puts "Usage: rails user:set_growth EMAIL=user@example.com"
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    user.update!(subscription_tier: "growth")
    puts "✅ #{user.email} is now Growth"
  end

  desc "Set user to Pro tier: rails user:set_pro EMAIL=user@example.com"
  task set_pro: :environment do
    email = ENV["EMAIL"]
    if email.blank?
      puts "Usage: rails user:set_pro EMAIL=user@example.com"
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    user.update!(subscription_tier: "pro")
    puts "✅ #{user.email} is now Pro"
  end

  desc "Set user to Free tier: rails user:set_free EMAIL=user@example.com"
  task set_free: :environment do
    email = ENV["EMAIL"]
    if email.blank?
      puts "Usage: rails user:set_free EMAIL=user@example.com"
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    user.update!(subscription_tier: "free")
    puts "✅ #{user.email} is now Free"
  end
end
