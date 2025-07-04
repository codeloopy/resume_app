class AddCustomSkillsTitleToResume < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:resumes, :skills_title)
      add_column :resumes, :skills_title, :string
    end
  end
end
