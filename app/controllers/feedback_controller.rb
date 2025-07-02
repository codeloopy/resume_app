class FeedbackController < ApplicationController
  before_action :authenticate_user!

  def create
    Feedback.create(reason: params[:reason], user: current_user)
    current_user.destroy!
    reset_session
    redirect_to root_path, notice: "Sorry to see you go! Your account has been deleted. Thanks for the feedback!"
  end
end
