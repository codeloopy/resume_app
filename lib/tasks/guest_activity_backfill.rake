# frozen_string_literal: true

namespace :guest do
  desc "Backfill GuestActivity signup records for existing guest users (one-time, for pre-tracking guests)"
  task backfill_signups: :environment do
    backfilled = 0
    User.where(guest: true).find_each do |user|
      next if GuestActivity.exists?(event_type: "signup", guest_user_id: user.id)

      GuestActivity.create!(
        event_type: "signup",
        guest_user_id: user.id,
        created_at: user.created_at
      )
      backfilled += 1
    end
    puts "Backfilled #{backfilled} guest signup record(s). Total signups now: #{GuestActivity.signups.count}"
  end
end
