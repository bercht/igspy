class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :stripe_price_id
      t.string :status
      t.datetime :current_period_end
      t.datetime :cancel_at

      t.timestamps
    end
  end
end
