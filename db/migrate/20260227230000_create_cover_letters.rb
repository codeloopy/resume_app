# frozen_string_literal: true

class CreateCoverLetters < ActiveRecord::Migration[7.2]
  def change
    create_table :cover_letters do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :title
      t.string :company_name
      t.string :job_title
      t.text :job_description
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
