class AddCustomSkillsTitleToResume < ActiveRecord::Migration[7.2]
  def change
    add_column :resumes, :skills_title, :string
  end
end
