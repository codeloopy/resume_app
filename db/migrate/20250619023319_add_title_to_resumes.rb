class AddTitleToResumes < ActiveRecord::Migration[7.2]
  def change
    add_column :resumes, :title, :string
  end
end
