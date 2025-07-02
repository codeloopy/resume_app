class CreateFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :feedbacks do |t|
      t.string :reason
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
