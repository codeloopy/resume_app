class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    added_attrs = [
      :first_name, :last_name, :phone, :location,
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
    begin
      @resumes = Resume.all
    rescue => e
      # Log the error but don't crash the sitemap
      Rails.logger.error "Sitemap generation error: #{e.message}"
      @resumes = []
    end

    # Ensure @resumes is always set
    @resumes ||= []

    respond_to do |format|
      format.xml
    end
  end

  # Helper method to determine if current page should be blocked from indexing
  def should_block_indexing?
    # Always allow public pages to be indexed
    return false if controller_name == "static_pages" && action_name == "home"
    return false if controller_name == "resumes" && action_name == "public"
    return false if controller_name == "resumes" && action_name == "public_pdf_modern"
    return false if controller_name == "resumes" && action_name == "public_pdf_classic"
    return false if controller_name == "resumes" && action_name == "public_pdf"

    # Block all authenticated user pages
    return true if user_signed_in?

    # Allow login/signup pages to be indexed for user acquisition
    return false if controller_name == "devise/sessions" && action_name == "new"
    return false if controller_name == "devise/registrations" && action_name == "new"

    # Default to allowing indexing for other public pages
    false
  end

  helper_method :should_block_indexing?
end
