# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :scraping
  has_many :messages, dependent: :destroy

  validates :thread_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active archived] }

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }

  def active?
    status == "active"
  end

  def archived?
    status == "archived"
  end
end