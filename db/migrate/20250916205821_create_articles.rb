class CreateArticles < ActiveRecord::Migration[7.2]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :published, default: false

      t.timestamps
    end
  end
end
