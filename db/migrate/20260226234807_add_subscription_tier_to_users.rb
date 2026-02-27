class AddSubscriptionTierToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :subscription_tier, :string, default: "free", null: false
  end
end
