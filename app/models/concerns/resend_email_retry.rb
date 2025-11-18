# frozen_string_literal: true

# Concern for handling Resend email delivery with retry logic
module ResendEmailRetry
  extend ActiveSupport::Concern

  # Maximum number of retry attempts
  MAX_RETRIES = 3

  # Base delay in seconds for exponential backoff
  BASE_DELAY = 2

  # Transient error classes that should be retried
  # Only define if Resend is loaded
  # Note: JSON::ParserError is handled separately to check if it's Resend-related
  TRANSIENT_ERRORS = begin
    errors = []
    if defined?(Resend::Error)
      # Check each error class individually to avoid NameError if they don't exist
      %w[
        InternalServerError
        ServiceUnavailable
        TimeoutError
      ].each do |error_name|
        if Resend::Error.const_defined?(error_name, false)
          errors << Resend::Error.const_get(error_name)
        end
      end
    end
    errors.freeze
  end

  # Permanent error classes that should NOT be retried
  # Only define if Resend is loaded
  PERMANENT_ERRORS = begin
    errors = []
    if defined?(Resend::Error)
      # Check each error class individually to avoid NameError if they don't exist
      %w[
        BadRequest
        Unauthorized
        Forbidden
        NotFound
        UnprocessableEntity
      ].each do |error_name|
        if Resend::Error.const_defined?(error_name, false)
          errors << Resend::Error.const_get(error_name)
        end
      end
    end
    errors.freeze
  end

  # Module-level method for delivering with retry (can be called from anywhere)
  # NOTE: In production, retry logic is handled at the delivery method level (config/initializers/resend.rb).
  # This method is a passthrough in production to avoid double retry wrapping.
  # In non-production environments, it provides retry logic if needed.
  def self.deliver_with_retry(mail, retries: MAX_RETRIES)
    # In production, retries are already handled at the delivery method level
    # Just call deliver_now which will use the wrapped delivery method
    if Rails.env.production?
      return mail.deliver_now
    end

    # For non-production environments, provide retry logic if needed
    attempt = 0
    last_error = nil

    while attempt <= retries
      begin
        return mail.deliver_now
      rescue *TRANSIENT_ERRORS => e
        last_error = e
        attempt += 1

        if attempt <= retries
          delay = calculate_delay(attempt)
          Rails.logger.warn(
            "Resend transient error (attempt #{attempt}/#{retries}): #{e.class} - #{e.message}. " \
            "Retrying in #{delay} seconds..."
          )
          sleep(delay)
        else
          Rails.logger.error(
            "Resend failed after #{retries} retries: #{e.class} - #{e.message}"
          )
          raise e
        end
      rescue JSON::ParserError => e
        # JSON::ParserError needs special handling to check if it's Resend-related
        error_message = e.message.to_s.downcase
        if error_message.include?("<!doctype html>") || error_message.include?("cloudflare")
          last_error = e
          attempt += 1

          if attempt <= retries
            delay = calculate_delay(attempt)
            Rails.logger.warn(
              "Resend returned HTML instead of JSON (attempt #{attempt}/#{retries}): #{e.message[0..100]}. " \
              "Retrying in #{delay} seconds..."
            )
            sleep(delay)
          else
            Rails.logger.error(
              "Resend failed after #{retries} retries (HTML response): #{e.message[0..100]}"
            )
            raise e
          end
        else
          # Not a Resend-related JSON error, re-raise
          raise e
        end
      rescue *PERMANENT_ERRORS => e
        # Don't retry permanent errors
        Rails.logger.error(
          "Resend permanent error (not retrying): #{e.class} - #{e.message}"
        )
        raise e
      rescue Resend::Error => e
        # Unknown Resend error - check if it looks transient
        if transient_error?(e)
          last_error = e
          attempt += 1

          if attempt <= retries
            delay = calculate_delay(attempt)
            Rails.logger.warn(
              "Resend unknown error (attempt #{attempt}/#{retries}): #{e.class} - #{e.message}. " \
              "Retrying in #{delay} seconds..."
            )
            sleep(delay)
          else
            Rails.logger.error(
              "Resend failed after #{retries} retries: #{e.class} - #{e.message}"
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

    # Should never reach here, but just in case
    raise last_error if last_error
  end

  def self.calculate_delay(attempt)
    BASE_DELAY * (2**(attempt - 1))
  end

  def self.transient_error?(error)
    return true if TRANSIENT_ERRORS.any? { |klass| error.is_a?(klass) }
    return false if PERMANENT_ERRORS.any? { |klass| error.is_a?(klass) }

    # Check error message for transient indicators
    error_message = error.message.to_s.downcase
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

    transient_indicators.any? { |indicator| error_message.include?(indicator) }
  end

  class_methods do
    # Delegate to module method
    def deliver_with_retry(mail, retries: MAX_RETRIES)
      ResendEmailRetry.deliver_with_retry(mail, retries: retries)
    end
  end

  # Instance method for mailers
  def deliver_with_retry(retries: MAX_RETRIES)
    self.class.deliver_with_retry(self, retries: retries)
  end
end
