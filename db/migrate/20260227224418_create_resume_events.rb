class CreateResumeEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :resume_events do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :event_type, null: false

      t.timestamps
    end

    add_index :resume_events, [ :resume_id, :event_type, :created_at ]
  end
end
