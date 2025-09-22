class ArticlesController < ApplicationController
  layout "blog"

  def index
    @pagy, @articles = pagy(Article.order(published_at: :desc), items: 6)
  rescue Pagy::OverflowError
    redirect_to blog_path(page: 1)
  end
end
