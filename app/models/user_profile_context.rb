class UserProfileContext < ApplicationRecord
  belongs_to :user
  
  # Enums para facilitar queries
  enum status: {
    pending: 'pending',
    processing: 'processing', 
    completed: 'completed',
    failed: 'failed'
  }, _suffix: true
  
  enum communication_tone: {
    formal: 'formal',
    casual: 'casual',
    technical: 'technical',
    inspirational: 'inspirational',
    educational: 'educational'
  }, _prefix: true
  
  # Scopes úteis
  scope :latest, -> { order(created_at: :desc).limit(1) }
  scope :completed_only, -> { where(status: 'completed') }
  
  # Serializar temas como array
  serialize :frequent_themes, coder: JSON
  
  # Validações
  validates :user_id, presence: true
  validates :status, presence: true
end