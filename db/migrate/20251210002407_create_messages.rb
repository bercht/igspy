class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false  # "user" ou "assistant"
      t.text :content, null: false
      t.string :message_id  # ID da mensagem na OpenAI (para assistants)
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :messages, :role
    add_index :messages, :message_id
    add_index :messages, :metadata, using: :gin
    add_index :messages, [:conversation_id, :created_at]
  end
end