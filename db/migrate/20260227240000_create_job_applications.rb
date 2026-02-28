# frozen_string_literal: true

class CreateJobApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :job_applications do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :company, null: false
      t.string :role, null: false
      t.string :status, default: "applied", null: false
      t.text :notes
      t.date :applied_at
      t.date :next_follow_up_at

      t.timestamps
    end

    add_index :job_applications, [ :resume_id, :status ]
    add_index :job_applications, [ :resume_id, :applied_at ]
  end
end
