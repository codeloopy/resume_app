class CreateExperiences < ActiveRecord::Migration[7.2]
  def change
    create_table :experiences do |t|
      t.string :company_name
      t.string :location
      t.string :title
      t.date :start_date
      t.date :end_date
      t.references :resume, null: false, foreign_key: true

      t.timestamps
    end
  end
end
