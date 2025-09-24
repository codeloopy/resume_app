class ArticlesController < ApplicationController
  layout "blog"

  def index
    @pagy, @articles = pagy(Article.order(published_at: :desc), items: 6)
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

  private

  def article_params
    params.require(:article).permit(:title, :body, :image, :category, :read_time, :author, :author_initials, :featured, :color, :icon, :published_at)
  end
end
