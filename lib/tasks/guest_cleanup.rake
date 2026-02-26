# frozen_string_literal: true

namespace :guest do
  desc "Clean up guest users older than 24 hours"
  task cleanup: :environment do
    count = User.cleanup_old_guests(24)
    puts "Cleaned up #{count} guest user(s) older than 24 hours."

    if count.positive?
      Rails.logger.info "[guest:cleanup] Removed #{count} guest account(s)"
    end
  end
end
