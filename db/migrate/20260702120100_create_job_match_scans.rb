# frozen_string_literal: true

class CreateJobMatchScans < ActiveRecord::Migration[7.2]
  def change
    create_table :job_match_scans do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :job_title
      t.string :company_name
      t.text :job_description, null: false
      t.integer :match_score, null: false
      t.jsonb :result, default: {}, null: false

      t.timestamps
    end

    add_index :job_match_scans, [ :resume_id, :created_at ]
  end
end
