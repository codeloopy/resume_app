class AddSlugToResumes < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:resumes, :slug)
      add_column :resumes, :slug, :string
    end

    unless index_exists?(:resumes, :slug)
      add_index :resumes, :slug, unique: true
    end
  end
end
