class AddResumeFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone, :string
    add_column :users, :linked_in_url, :string
    add_column :users, :github_url, :string
    add_column :users, :portfolio, :string
  end
end
