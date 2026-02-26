class Admin::DashboardController < Admin::BaseController
  def index
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page, limit: 10)
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page, limit: 10)
    @pagy_users, @users = pagy(User.all, page_param: :user_page, limit: 10)
    @pagy_articles, @articles = pagy(Article.all, page_param: :article_page, limit: 10)
    @guest_stats_today = GuestActivity.stats_for_period(Time.current.beginning_of_day)
    @guest_stats_7_days = GuestActivity.stats_for_period(7.days.ago)
    @guest_conversion_rate_today = GuestActivity.conversion_rate(Time.current.beginning_of_day)
    @guest_conversion_rate_7_days = GuestActivity.conversion_rate(7.days.ago)
    @current_guest_count = User.where(guest: true).count
    @total_guest_signups_all_time = GuestActivity.signups.count
  end

  def feedbacks
    @pagy_feedbacks, @feedbacks = pagy(Feedback.all, page_param: :feedback_page, limit: 10)
    render partial: "feedback_data", locals: { feedbacks: @feedbacks, pagy: @pagy_feedbacks }
  end

  def resumes
    @pagy_resumes, @resumes = pagy(Resume.all, page_param: :resume_page, limit: 10)
    render partial: "resume_data", locals: { resumes: @resumes, pagy: @pagy_resumes }
  end

  def users
    @pagy_users, @users = pagy(User.all, page_param: :user_page, limit: 10)
    render partial: "users_data", locals: { users: @users, pagy: @pagy_users }
  end

  def articles
    @pagy_articles, @articles = pagy(Article.all, page_param: :article_page, limit: 10)
    render partial: "articles_data", locals: { articles: @articles, pagy: @pagy_articles }
  end
end
