class Admin::DashboardController < ApplicationController
  def index
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page, items: 10)
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page)
    @pagy_users, @users = pagy(User.all, page_param: :user_page)
    @pagy_articles, @articles = pagy(Article.all, page_param: :article_page, items: 10)
  end

  def feedbacks
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page, items: 10)
    render partial: "feedback_data", locals: { feedbacks: @feedbacks, pagy: @pagy_feedbacks }
  end

  def resumes
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page, items: 10)
    render partial: "resume_data", locals: { resumes: @resumes, pagy: @pagy_resumes }
  end

  def users
    @pagy_users, @users = pagy(User.all, page_param: :user_page, items: 10)
    render partial: "users_data", locals: { users: @users, pagy: @pagy_users }
  end

  def articles
    @pagy_articles, @articles = pagy(Article.all, page_param: :article_page, items: 10)
    render partial: "articles_data", locals: { articles: @articles, pagy: @pagy_articles }
  end
end
