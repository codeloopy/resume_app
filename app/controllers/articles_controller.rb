class ArticlesController < ApplicationController
  before_action :set_article, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :require_admin!, except: [ :index, :show ]
  layout "blog"

  def index
    @featured_article = Article.published.where(featured: true).order(published_at: :desc).first
    @pagy, @articles = pagy(
      Article.published.where.not(id: @featured_article&.id).order(published_at: :desc),
      limit: 9
    )
  rescue Pagy::OverflowError
    redirect_to blog_path(page: 1)
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to articles_path, notice: "Article created successfully"
    end
  end

  def show
    @latest_articles = Article.published.order(published_at: :desc).limit(3)
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to articles_path, notice: "Article updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: "Article deleted successfully"
  end

  private

  def set_article
    @article = Article.friendly.find(params[:slug])
    # For non-admin users, only show published articles
    unless current_user&.admin?
      not_found unless @article.published_at <= Time.current
    end
  end

  def article_params
    params.require(:article).permit(:title, :body, :image, :category, :read_time, :author, :author_initials, :featured, :color, :icon, :published_at)
  end

  def require_admin!
    redirect_to articles_path, alert: "You are not authorized to access this page." unless current_user&.admin?
  end
end
