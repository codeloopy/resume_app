# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    super do |resource|
      if resource.errors.empty?
        redirect_to resume_path and return
      end
    end
  end

  def upgrade_form
    # This action renders the upgrade form for guest users
    # Ensure user is authenticated and is a guest
    unless current_user&.guest?
      redirect_to root_path, alert: "Only guest users can access this page."
      return
    end

    # Set the resource variable for the Devise form
    @resource = current_user
    render "devise/registrations/upgrade"
  end

    def upgrade
    # Ensure user is authenticated and is a guest
    unless current_user&.guest?
      redirect_to root_path, alert: "Only guest users can access this page."
      return
    end

    if current_user.update(user_params.merge(guest: false))
      GuestActivity.track!(
        event_type: "converted",
        guest_user: current_user,
        session_id: session.id&.to_s
      )
      # Sign the user in again after updating their credentials
      # This ensures they stay authenticated after the guest->regular conversion
      sign_in(current_user, bypass: true)
      redirect_to resume_path(current_user.resume), notice: "Your account is saved!"
    else
      # Set the resource variable for the Devise form when re-rendering
      @resource = current_user
      render "devise/registrations/upgrade"
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    resume_wizard_path(:summary)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone, :location, :linked_in_url, :github_url, :portfolio)
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
