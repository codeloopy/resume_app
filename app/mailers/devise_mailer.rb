class DeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # gives access to `confirmation_url`, etc.
  default template_path: "devise/mailer" # to make sure that your mailer uses the devise views

  def reset_password_instructions(record, token, opts = {})
    super
  rescue Resend::Error => e
    Rails.logger.error "***** ERROR: Resend failed for password reset email"
    Rails.logger.error "***** ERROR: User: #{record.email}"
    Rails.logger.error "***** ERROR: Error: #{e.message}"

    # Log additional details for debugging
    if e.respond_to?(:response) && e.response
      Rails.logger.error "***** ERROR: Resend Response: #{e.response.inspect}"
    end

    if e.respond_to?(:code) && e.code
      Rails.logger.error "***** ERROR: Resend Error Code: #{e.code}"
    end

    # Re-raise the exception to maintain the original behavior
    raise e
  end

  def confirmation_instructions(record, token, opts = {})
    super
  rescue Resend::Error => e
    Rails.logger.error "***** ERROR: Resend failed for confirmation email"
    Rails.logger.error "***** ERROR: User: #{record.email}"
    Rails.logger.error "***** ERROR: Error: #{e.message}"
    raise e
  end

  def unlock_instructions(record, token, opts = {})
    super
  rescue Resend::Error => e
    Rails.logger.error "***** ERROR: Resend failed for unlock email"
    Rails.logger.error "***** ERROR: User: #{record.email}"
    Rails.logger.error "***** ERROR: Error: #{e.message}"
    raise e
  end

  def email_changed(record, opts = {})
    super
  rescue Resend::Error => e
    Rails.logger.error "***** ERROR: Resend failed for email change notification"
    Rails.logger.error "***** ERROR: User: #{record.email}"
    Rails.logger.error "***** ERROR: Error: #{e.message}"
    raise e
  end

  def password_change(record, opts = {})
    super
  rescue Resend::Error => e
    Rails.logger.error "***** ERROR: Resend failed for password change notification"
    Rails.logger.error "***** ERROR: User: #{record.email}"
    Rails.logger.error "***** ERROR: Error: #{e.message}"
    raise e
  end
end
