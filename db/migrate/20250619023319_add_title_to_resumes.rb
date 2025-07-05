class AddTitleToResumes < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:resumes, :title)
      add_column :resumes, :title, :string
    end
  end
end
