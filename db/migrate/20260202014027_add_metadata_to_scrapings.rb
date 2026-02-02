class AddMetadataToScrapings < ActiveRecord::Migration[7.2]
  def change
    add_column :scrapings, :metadata, :jsonb, default: {}, null: false
    
    # Índice GIN para queries em JSON
    add_index :scrapings, :metadata, using: :gin
  end
end