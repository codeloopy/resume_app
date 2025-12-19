# frozen_string_literal: true

# Only initialize Sentry in production
if Rails.env.production?
  begin
    require "sentry-ruby"
    require "sentry-rails"

    Sentry.init do |config|
      config.dsn = "https://37e3e7f914dea837f69e0cc7d14570f8@o4507951856025600.ingest.us.sentry.io/4509578236002304"
      config.enable_logs = true
      config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

      # Add data like request headers and IP for users,
      # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
      config.enabled_patches << :active_job
      config.send_default_pii = true

      # Filter out system-level exceptions that shouldn't be reported
      config.before_send = lambda do |event, hint|
        exception = hint[:exception]

        # Don't send SignalException (SIGTERM, SIGINT, etc.)
        return nil if exception.is_a?(SignalException)

        # Don't send SystemExit exceptions
        return nil if exception.is_a?(SystemExit)

        # Don't send Interrupt exceptions
        return nil if exception.is_a?(Interrupt)

        # Don't send exceptions from the boot process
        if exception.backtrace&.first&.include?("config/boot")
          return nil
        end

        # Filter out transient Resend errors (infrastructure issues)
        # Check if Resend is loaded (it might not be in all environments)
        if defined?(Resend) && (exception.is_a?(Resend::Error) || exception.is_a?(JSON::ParserError))
          # Check if this is a transient error
          is_transient = false

          # Check for known transient error classes
          # Use const_defined? to safely check each error class
          if defined?(Resend::Error)
            transient_classes = []
            %w[InternalServerError ServiceUnavailable TimeoutError].each do |error_name|
              if Resend::Error.const_defined?(error_name, false)
                transient_classes << Resend::Error.const_get(error_name)
              end
            end
            is_transient = true if transient_classes.any? { |klass| exception.is_a?(klass) }
          end

          # Check for JSON::ParserError with HTML response (Cloudflare errors)
          if exception.is_a?(JSON::ParserError)
            error_message = exception.message.to_s.downcase
            is_transient = true if error_message.include?("<!doctype html>") || error_message.include?("cloudflare")
          end

          # Check error message for transient indicators
          unless is_transient
            error_message = exception.message.to_s.downcase
            transient_indicators = [
              "internal server error",
              "service unavailable",
              "timeout",
              "temporarily",
              "try again",
              "cloudflare",
              "502",
              "503",
              "504"
            ]
            is_transient = true if transient_indicators.any? { |indicator| error_message.include?(indicator) }
          end

          # Don't report transient errors to Sentry (they're infrastructure issues)
          if is_transient
            Rails.logger.debug("Filtering transient Resend error from Sentry: #{exception.class} - #{exception.message[0..100]}")
            return nil
          end
        elsif exception.is_a?(JSON::ParserError)
          # Also check JSON::ParserError even if Resend isn't loaded (might be from Resend)
          error_message = exception.message.to_s.downcase
          if error_message.include?("<!doctype html>") || error_message.include?("cloudflare") || error_message.include?("resend")
            Rails.logger.debug("Filtering transient JSON parse error (likely Resend infrastructure issue) from Sentry: #{exception.message[0..100]}")
            return nil
          end
        end

        event
      end
    end
  rescue LoadError => e
    Rails.logger.warn "Sentry gems not available: #{e.message}"
  end
end
