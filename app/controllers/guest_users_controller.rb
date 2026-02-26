class GuestUsersController < ApplicationController
  def create
    user = User.create_guest
    sign_in(user)
    GuestActivity.track!(event_type: "signup", guest_user: user, session_id: session.id&.to_s)
    redirect_to resume_wizard_path(:summary)
  end
end
