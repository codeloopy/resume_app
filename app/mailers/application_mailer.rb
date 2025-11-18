class ApplicationMailer < ActionMailer::Base
  include ResendEmailRetry
  default from: "noreply@freeresumebuilderapp.com"
  layout "mailer"
end
