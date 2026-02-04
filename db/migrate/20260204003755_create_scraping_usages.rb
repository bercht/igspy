class CreateScrapingUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :scraping_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.date :period, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end

    add_index :scraping_usages, [:user_id, :period], unique: true
  end
end