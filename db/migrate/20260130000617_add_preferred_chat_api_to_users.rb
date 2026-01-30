class AddPreferredChatApiToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :preferred_chat_api, :string
    add_index :users, :preferred_chat_api
  end
end