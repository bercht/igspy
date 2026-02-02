# db/migrate/20260202_create_profile_stats.rb
class CreateProfileStats < ActiveRecord::Migration[7.2]
  def change
    create_table :profile_stats do |t|
      # Relacionamento
      t.references :user, null: false, foreign_key: true
      
      # Dados básicos do perfil (snapshot)
      t.string :username
      t.string :full_name
      t.text :biography
      
      # Métricas principais
      t.integer :followers, default: 0
      t.integer :following, default: 0
      t.integer :posts, default: 0
      
      # URLs
      t.string :profile_url
      t.string :profile_image_url
      
      # Flags
      t.boolean :is_private, default: false
      
      # Metadata extra (JSONB para flexibilidade futura)
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    # Índices para performance
    add_index :profile_stats, [:user_id, :created_at], order: { created_at: :desc }
    add_index :profile_stats, :username
    add_index :profile_stats, :metadata, using: :gin
  end
end