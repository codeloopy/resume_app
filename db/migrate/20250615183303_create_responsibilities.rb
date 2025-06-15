class CreateResponsibilities < ActiveRecord::Migration[7.2]
  def change
    create_table :responsibilities do |t|
      t.string :content
      t.references :experience, null: false, foreign_key: true

      t.timestamps
    end
  end
end
