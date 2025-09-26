class RemovePublishedToArticleModel < ActiveRecord::Migration[7.2]
  def change
    remove_column :articles, :published, :boolean
  end
end
