class CreateScrapings < ActiveRecord::Migration[7.2]
  def change
    create_table :scrapings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :profile_url
      t.integer :results_limit
      t.string :status
      t.string :status_message
      t.bigint :scraping_id
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
