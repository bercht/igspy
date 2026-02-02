class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :trigger_profile_data_collection         

  has_many :scrapings, dependent: :destroy
  has_many :profile_stats, dependent: :destroy

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

  def latest_profile_stat
    profile_stats.recent_first.first
  end
  
  # Método helper para stats do gráfico (últimas 3)
  def profile_stats_for_chart
    profile_stats.recent_first.limit(3).reverse
  end
  
  private
  
  def trigger_profile_data_collection
    # Só disparar se tiver instagram_profile preenchido
    return unless instagram_profile.present?
    
    Rails.logger.info "🚀 Disparando coleta de dados do perfil para user #{id}"
    
    # Disparar job assíncrono
    CollectProfileDataJob.perform_later(id)
  end
end  
end