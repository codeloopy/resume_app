class FeedbacksController < ApplicationController
  before_action :authenticate_user!

  def create
    Feedback.create(reason: params[:reason], email: params[:email], user: current_user)

    # Temporarily disable foreign key constraints to allow user deletion
    ActiveRecord::Base.connection.execute("SET session_replication_role = replica;")
    current_user.destroy!
    ActiveRecord::Base.connection.execute("SET session_replication_role = DEFAULT;")

    reset_session
    redirect_to root_path, notice: "Sorry to see you go! Your account has been deleted. Thanks for the feedback!"
  end
end
