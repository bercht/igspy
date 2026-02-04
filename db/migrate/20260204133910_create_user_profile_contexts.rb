class CreateUserProfileContexts < ActiveRecord::Migration[7.2]
  def change
    create_table :user_profile_contexts do |t|
      t.references :user, null: false, foreign_key: true
      
      # Dados extraídos automaticamente
      t.string :detected_niche
      t.text :detected_audience
      t.string :communication_tone
      t.text :frequent_themes
      
      # Análise completa em texto
      t.text :full_analysis
      
      # Status do processamento
      t.string :status, default: 'pending', null: false
      
      # Permitir edição manual
      t.boolean :manually_edited, default: false
      t.text :user_corrections
      
      t.timestamps
    end
    
    add_index :user_profile_contexts, [:user_id, :created_at], order: { created_at: :desc }
    add_index :user_profile_contexts, :status
  end
end