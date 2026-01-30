class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :scrapings, dependent: :destroy

  # Validações para API keys (opcional - permite vazio)
  validates :manus_api_key, format: { with: /\A[a-zA-Z0-9_-]*\z/, allow_blank: true }, if: -> { manus_api_key.present? }
  validates :anthropic_api_key, format: { with: /\A[a-zA-Z0-9_-]*\z/, allow_blank: true }, if: -> { anthropic_api_key.present? }
  
  # Validação de escolha de API de chat
  validates :preferred_chat_api, inclusion: { in: %w[openai anthropic], allow_nil: true }
  
  # Métodos auxiliares
  def has_chat_api?
    preferred_chat_api.present? && api_key_for_chat.present?
  end
  
  def api_key_for_chat
    case preferred_chat_api
    when 'openai'
      ENV['OPENAI_API_KEY'] # Usar a key global do sistema
    when 'anthropic'
      anthropic_api_key
    end
  end
end