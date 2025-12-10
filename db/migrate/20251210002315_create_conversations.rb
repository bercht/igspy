class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.references :scraping, null: false, foreign_key: true
      t.string :thread_id, null: false
      t.string :status, default: "active", null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :conversations, :thread_id, unique: true
    add_index :conversations, :status
    add_index :conversations, :metadata, using: :gin
  end
end