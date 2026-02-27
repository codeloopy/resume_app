# frozen_string_literal: true

class AddCurrentResumeIdToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :current_resume_id, :bigint
    add_foreign_key :users, :resumes, column: :current_resume_id

    # Set current_resume_id for existing users with a single resume
    User.reset_column_information
    User.find_each do |user|
      resume = Resume.find_by(user_id: user.id)
      user.update_column(:current_resume_id, resume.id) if resume
    end
  end

  def down
    remove_foreign_key :users, :resumes, column: :current_resume_id
    remove_column :users, :current_resume_id
  end
end
