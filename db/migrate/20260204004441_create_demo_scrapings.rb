class CreateDemoScrapings < ActiveRecord::Migration[7.1]
  def change
    create_table :demo_scrapings do |t|
      t.string :profile_username, null: false, index: { unique: true }
      t.jsonb :profile_data, null: false, default: {}
      t.jsonb :cached_analysis, null: false, default: {}
      t.datetime :last_refreshed_at

      t.timestamps
    end
  end
end