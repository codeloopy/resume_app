class AddMetaDescriptionToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :meta_description, :text
  end
end
