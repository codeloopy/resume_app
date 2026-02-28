# frozen_string_literal: true

class AddCoverLetterPurchasedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :cover_letter_purchased, :boolean, default: false, null: false
  end
end
