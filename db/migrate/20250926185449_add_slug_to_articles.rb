class AddSlugToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :slug, :string
  end
end
