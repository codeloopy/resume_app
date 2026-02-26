class CreateGuestActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :guest_activities do |t|
      t.string :event_type, null: false
      t.string :session_id
      t.bigint :guest_user_id
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :guest_activities, :event_type
    add_index :guest_activities, :created_at
    add_index :guest_activities, [ :event_type, :created_at ]
  end
end
