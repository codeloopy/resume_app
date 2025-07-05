class AddLocationToUsers < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:users, :location)
      add_column :users, :location, :string
    end
  end
end
