# Configure Resend for Action Mailer
# Only configure in production and when the app is fully loaded
Rails.application.config.after_initialize do
  if Rails.env.production?
    Rails.logger.info "***** Configuring Resend for production..."

    resend_credentials = Rails.application.credentials.resend
    Rails.logger.info "***** Resend credentials found: #{resend_credentials.present?}"

    if resend_credentials&.dig(:api_key)
      Rails.logger.info "***** Setting up Resend with API key: #{resend_credentials[:api_key][0..10]}..."

      # Configure the Resend gem with the API key
      require "resend"
      Resend.api_key = resend_credentials[:api_key]

      # Don't set delivery_method here since it's already set in production.rb
      # ActionMailer::Base.delivery_method = :resend

      # Wrap Resend delivery method with retry logic
      if defined?(ActionMailer::Base::ResendDeliveryMethod)
        original_deliver = ActionMailer::Base::ResendDeliveryMethod.instance_method(:deliver!)

        ActionMailer::Base::ResendDeliveryMethod.define_method(:deliver!) do |mail|
          attempt = 0
          max_retries = ResendEmailRetry::MAX_RETRIES
          last_error = nil

          while attempt <= max_retries
            begin
              return original_deliver.bind(self).call(mail)
            rescue JSON::ParserError => e
              # JSON::ParserError must be handled FIRST to check if it's Resend-related
              # before falling through to generic transient error handling
              error_message = e.message.to_s.downcase
              if error_message.include?("<!doctype html>") || error_message.include?("cloudflare")
                last_error = e
                attempt += 1

                if attempt <= max_retries
                  delay = ResendEmailRetry.calculate_delay(attempt)
                  Rails.logger.warn(
                    "Resend returned HTML instead of JSON (attempt #{attempt}/#{max_retries}): #{e.message[0..100]}. " \
                    "Retrying in #{delay} seconds..."
                  )
                  sleep(delay)
                else
                  Rails.logger.error(
                    "Resend failed after #{max_retries} retries (HTML response): #{e.message[0..100]}"
                  )
                  raise e
                end
              else
                # Not a Resend-related JSON error, re-raise immediately
                raise e
              end
            rescue *ResendEmailRetry::TRANSIENT_ERRORS => e
              last_error = e
              attempt += 1

              if attempt <= max_retries
                delay = ResendEmailRetry.calculate_delay(attempt)
                Rails.logger.warn(
                  "Resend transient error (attempt #{attempt}/#{max_retries}): #{e.class} - #{e.message}. " \
                  "Retrying in #{delay} seconds..."
                )
                sleep(delay)
              else
                Rails.logger.error(
                  "Resend failed after #{max_retries} retries: #{e.class} - #{e.message}"
                )
                raise e
              end
            rescue *ResendEmailRetry::PERMANENT_ERRORS => e
              # Don't retry permanent errors
              Rails.logger.error(
                "Resend permanent error (not retrying): #{e.class} - #{e.message}"
              )
              raise e
            rescue Resend::Error => e
              # Unknown Resend error - check if it looks transient
              if ResendEmailRetry.transient_error?(e)
                last_error = e
                attempt += 1

                if attempt <= max_retries
                  delay = ResendEmailRetry.calculate_delay(attempt)
                  Rails.logger.warn(
                    "Resend unknown error (attempt #{attempt}/#{max_retries}): #{e.class} - #{e.message}. " \
                    "Retrying in #{delay} seconds..."
                  )
                  sleep(delay)
                else
                  Rails.logger.error(
                    "Resend failed after #{max_retries} retries: #{e.class} - #{e.message}"
                  )
                  raise e
                end
              else
                Rails.logger.error(
                  "Resend permanent error (not retrying): #{e.class} - #{e.message}"
                )
                raise e
              end
            end
          end

          raise last_error if last_error
        end
      end

      # Add error handling for Resend errors with better classification
      ActionMailer::Base.rescue_from Resend::Error do |exception|
        # Determine if this is a transient error
        is_transient = ResendEmailRetry::TRANSIENT_ERRORS.any? { |klass| exception.is_a?(klass) } ||
                       ResendEmailRetry.transient_error?(exception)

        # Log error details
        Rails.logger.error "***** ERROR: Resend Error Details: #{exception.message}"
        Rails.logger.error "***** ERROR: Resend Error Class: #{exception.class}"
        Rails.logger.error "***** ERROR: Error Type: #{is_transient ? 'TRANSIENT' : 'PERMANENT'}"
        Rails.logger.error "***** ERROR: Resend Error Backtrace: #{exception.backtrace.first(10).join("\n")}"

        # Log additional error details if available
        if exception.respond_to?(:response) && exception.response
          Rails.logger.error "***** ERROR: Resend Response: #{exception.response.inspect}"
        end

        if exception.respond_to?(:code) && exception.code
          Rails.logger.error "***** ERROR: Resend Error Code: #{exception.code}"
        end

        # Log the email details that failed
        if exception.respond_to?(:email) && exception.email
          Rails.logger.error "***** ERROR: Failed Email Details: #{exception.email.inspect}"
        end

        # For transient errors, don't report to Sentry (they're infrastructure issues)
        # For permanent errors, let them bubble up to Sentry
        if is_transient
          Rails.logger.warn "***** WARNING: Transient Resend error - not reporting to Sentry"
          # Still raise the exception so the caller knows it failed, but Sentry will filter it
        end

        # Re-raise the exception to maintain the original behavior
        raise exception
      end

      # Also handle JSON::ParserError which can occur when Resend returns HTML
      ActionMailer::Base.rescue_from JSON::ParserError do |exception|
        # Check if this is related to Resend (HTML response instead of JSON)
        if exception.message.include?("<!DOCTYPE html>") || exception.message.include?("cloudflare")
          Rails.logger.error "***** ERROR: Resend returned HTML instead of JSON (infrastructure issue)"
          Rails.logger.error "***** ERROR: JSON::ParserError: #{exception.message[0..200]}"
          # This is a transient error, Sentry will filter it
        end
        raise exception
      end

      # Test Resend configuration
      # DISABLED: This was consuming daily quota - uncomment only for debugging
      # begin
      #   # Try to send a test email to verify configuration
      #   test_result = Resend::Emails.send({
      #     from: "noreply@freeresumebuilderapp.com",
      #     to: "test@example.com",
      #     subject: "Resend Configuration Test",
      #     html: "<p>This is a test email to verify Resend configuration.</p>"
      #   })
      #   Rails.logger.info "Resend configuration test successful: #{test_result.inspect}"
      # rescue Resend::Error => e
      #   Rails.logger.error "***** ERROR: Resend configuration test failed: #{e.message}"
      #   Rails.logger.error "***** ERROR: This might indicate domain verification issues or API key problems"
      # rescue => e
      #   Rails.logger.error "***** ERROR: Unexpected error during Resend test: #{e.message}"
      # end

      Rails.logger.info "***** Resend configuration completed successfully"
    else
      Rails.logger.error "***** ERROR: No Resend API key found in credentials!"
    end
  end
end
