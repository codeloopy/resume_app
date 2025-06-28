class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    added_attrs = [
      :first_name, :last_name, :phone,
      :linked_in_url, :github_url, :portfolio,
      :email, :password, :password_confirmation, :remember_me
    ]

    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  def after_sign_in_path_for(resource)
    resume_path
  end

  def sitemap
    @resumes = Resume.all
    respond_to do |format|
      format.xml
    end
  end
end
