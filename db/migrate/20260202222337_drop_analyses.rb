class DropAnalyses < ActiveRecord::Migration[7.2]
  def change
    drop_table :analyses
  end
end