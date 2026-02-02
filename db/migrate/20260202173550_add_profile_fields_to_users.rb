class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :cpf, :string
    add_column :users, :full_name, :string
    add_column :users, :instagram_profile, :string
    add_column :users, :phone, :string
    
    add_index :users, :cpf, unique: true
    add_index :users, :instagram_profile
  end
end