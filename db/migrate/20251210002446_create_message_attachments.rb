class CreateMessageAttachments < ActiveRecord::Migration[7.2]
  def change
    create_table :message_attachments do |t|
      t.references :message, null: false, foreign_key: true
      t.string :file_id, null: false  # ID do arquivo na OpenAI
      t.string :filename, null: false
      t.string :content_type
      t.integer :file_size
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :message_attachments, :file_id
    add_index :message_attachments, :metadata, using: :gin
  end
end