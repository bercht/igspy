class AddChatProviderToScrapingAnalyses < ActiveRecord::Migration[7.2]
  def change
    add_column :scraping_analyses, :chat_provider, :string, default: 'openai'
    add_index :scraping_analyses, :chat_provider
  end
end