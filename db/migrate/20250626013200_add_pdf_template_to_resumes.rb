class AddPdfTemplateToResumes < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:resumes, :pdf_template)
      add_column :resumes, :pdf_template, :string
    end
  end
end
