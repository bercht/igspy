class AddApiKeysToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :manus_api_key, :string
    add_column :users, :anthropic_api_key, :string
  end
end
