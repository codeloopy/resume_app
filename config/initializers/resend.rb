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

      # Add error handling for Resend errors
      ActionMailer::Base.rescue_from Resend::Error do |exception|
        Rails.logger.error "***** ERROR: Resend Error Details: #{exception.message}"
        Rails.logger.error "***** ERROR: Resend Error Class: #{exception.class}"
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

        # Re-raise the exception to maintain the original behavior
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
