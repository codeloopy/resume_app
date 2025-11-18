class DeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # gives access to `confirmation_url`, etc.
  default template_path: "devise/mailer" # to make sure that your mailer uses the devise views
  # Retry logic is inherited from ApplicationMailer via deliver_now override
end
