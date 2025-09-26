class AddExtraDataToArticleModel < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :image, :string
    add_column :articles, :category, :string
    add_column :articles, :read_time, :string
    add_column :articles, :author, :string
    add_column :articles, :author_initials, :string
    add_column :articles, :featured, :boolean
    add_column :articles, :color, :string
    add_column :articles, :icon, :string
    add_column :articles, :published_at, :datetime
  end
end
