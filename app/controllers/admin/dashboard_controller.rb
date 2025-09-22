class Admin::DashboardController < ApplicationController
  def index
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page)
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page)
    @pagy_users, @users = pagy(User.all, page_param: :user_page)
  end

  def feedbacks
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page)
    render partial: "feedback_data", locals: { feedbacks: @feedbacks, pagy: @pagy_feedbacks }
  end

  def resumes
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page)
    render partial: "resume_data", locals: { resumes: @resumes, pagy: @pagy_resumes }
  end

  def users
    @pagy_users, @users = pagy(User.all, page_param: :user_page)
    render partial: "users_data", locals: { users: @users, pagy: @pagy_users }
  end
end
