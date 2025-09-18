class ArticlesController < ApplicationController
  layout "blog"
  # include Pagy::Backend

  def index
    @pagy, @articles = pagy(Article.order(published_at: :desc))
  end
end
