# frozen_string_literal: true

class AddMonetizationFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :lifetime_access, default: false, null: false
      t.datetime :job_search_pass_expires_at
      t.integer :jd_scans_used, default: 0, null: false
      t.date :jd_scans_period_start
      t.integer :ai_credits_used, default: 0, null: false
      t.date :ai_credits_period_start
    end
  end
end
