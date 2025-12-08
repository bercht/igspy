class CreateScrapingAnalyses < ActiveRecord::Migration[7.2]
  def change
    create_table :scraping_analyses do |t|
      # Relacionamento
      t.references :scraping, null: false, foreign_key: true
      
      # Análise do GPT-4
      t.text :analysis_text, null: false
      
      # IDs do OpenAI
      t.string :assistant_id      # ID do Assistant criado
      t.string :vector_store_id   # ID do Vector Store
      t.string :file_id           # ID do arquivo enviado para OpenAI
      
      # Status da análise
      t.string :status, default: 'pending', null: false
      # Valores: 'pending', 'processing', 'completed', 'failed'
      
      # Metadata adicional (para dados extras do GPT)
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    # Índices para performance
    add_index :scraping_analyses, :status
    add_index :scraping_analyses, :assistant_id
    add_index :scraping_analyses, :created_at
    add_index :scraping_analyses, :metadata, using: :gin
  end
end