class AddPdfTemplateToResumes < ActiveRecord::Migration[7.2]
  def change
    add_column :resumes, :pdf_template, :string
  end
end
