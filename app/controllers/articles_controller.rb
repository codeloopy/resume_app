class ArticlesController < ApplicationController
  layout "blog"

  def index
    @articles = Article.all
  end
end
