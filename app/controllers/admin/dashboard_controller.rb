class Admin::DashboardController < ApplicationController
  def index
    @resumes = Resume.all
    @users = User.all
    @feedbacks = Feedback.all
  end
end
