class AddUniqueIndexToScrapingAnalyses < ActiveRecord::Migration[7.2]
  def change
    # Remove o índice não-único existente primeiro
    remove_index :scraping_analyses, :scraping_id
    # Adiciona unique
    add_index :scraping_analyses, :scraping_id, unique: true
  end
end