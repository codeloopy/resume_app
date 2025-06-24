# Configure Resend for Action Mailer
# Only configure in production and when the app is fully loaded
Rails.application.config.after_initialize do
  if Rails.env.production?
    # Rails.logger.info "Configuring Resend for production..."

    resend_credentials = Rails.application.credentials.resend
    # Rails.logger.info "Resend credentials: #{resend_credentials.inspect}"

    if resend_credentials&.dig(:api_key)
      # Rails.logger.info "Setting up Resend with API key: #{resend_credentials[:api_key][0..10]}..."

      # Configure the Resend gem with the API key
      require "resend"
      Resend.api_key = resend_credentials[:api_key]

      # Configure ActionMailer to use resend delivery method
      ActionMailer::Base.delivery_method = :resend

      # Add error handling for Resend errors
      ActionMailer::Base.rescue_from Resend::Error do |exception|
        Rails.logger.error "***** ERROR: Resend Error Details: #{exception.message}"
        Rails.logger.error "***** ERROR: Resend Error Class: #{exception.class}"
        Rails.logger.error "***** ERROR: Resend Error Backtrace: #{exception.backtrace.first(5).join("\n")}"
        raise exception
      end

      # Rails.logger.info "Resend configuration completed successfully"
    else
      Rails.logger.error "***** ERROR: No Resend API key found in credentials!"
    end
  end
end
