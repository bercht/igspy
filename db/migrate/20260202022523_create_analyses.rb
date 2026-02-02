class CreateAnalyses < ActiveRecord::Migration[7.2]
  def change
    create_table :analyses do |t|
      t.references :scraping, null: false, foreign_key: true
      t.string :thread_id
      t.string :assistant_id
      t.string :vector_store_id
      t.text :report
      t.string :status, default: 'pending'
      t.string :chat_provider # 'openai' ou 'anthropic'
      
      t.timestamps
    end
    
    add_index :analyses, :thread_id
    add_index :analyses, :status
  end
end