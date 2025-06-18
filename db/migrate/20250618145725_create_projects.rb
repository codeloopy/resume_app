class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :title
      t.string :description
      t.string :url
      t.references :resume, null: false, foreign_key: true

      t.timestamps
    end
  end
end
