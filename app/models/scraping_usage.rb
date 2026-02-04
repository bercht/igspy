class ScrapingUsage < ApplicationRecord
  belongs_to :user

  validates :period, presence: true
  validates :count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :period, message: "deve ter apenas um registro de uso por mês" }
end