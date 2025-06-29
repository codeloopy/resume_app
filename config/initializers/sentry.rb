# frozen_string_literal: true

# Only initialize Sentry in production
if Rails.env.production?
  require "sentry-ruby"
  require "sentry-rails"

  Sentry.init do |config|
    config.dsn = "https://37e3e7f914dea837f69e0cc7d14570f8@o4507951856025600.ingest.us.sentry.io/4509578236002304"
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # Add data like request headers and IP for users,
    # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
    config.enabled_patches << :active_job
    config.send_default_pii = true

    # Filter out system-level exceptions that shouldn't be reported
    config.before_send = lambda do |event, hint|
      # Don't send SignalException (SIGTERM, SIGINT, etc.)
      return nil if hint[:exception].is_a?(SignalException)

      # Don't send SystemExit exceptions
      return nil if hint[:exception].is_a?(SystemExit)

      # Don't send Interrupt exceptions
      return nil if hint[:exception].is_a?(Interrupt)

      # Don't send exceptions from the boot process
      if hint[:exception].backtrace&.first&.include?("config/boot")
        return nil
      end

      event
    end
  end
end
