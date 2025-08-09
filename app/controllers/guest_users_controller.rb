class GuestUsersController < ApplicationController
  def create
    user = User.create_guest
    sign_in(user)
    redirect_to resume_wizard_path(:summary)
  end
end
