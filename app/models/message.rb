# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  has_many :message_attachments, dependent: :destroy

  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :by_user, -> { where(role: "user") }
  scope :by_assistant, -> { where(role: "assistant") }

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end

  def has_attachments?
    message_attachments.any?
  end
end