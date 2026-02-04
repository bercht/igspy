# app/models/profile_stat.rb
class ProfileStat < ApplicationRecord
  # Relacionamentos
  belongs_to :user
  after_create :trigger_context_analysis
  
  # Validações
  validates :username, presence: true
  validates :followers, :following, :posts, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  
  # Métodos de classe
  def self.keep_latest(user, limit = 3)
    stats_to_delete = for_user(user)
                       .recent_first
                       .offset(limit)
    
    stats_to_delete.destroy_all
  end
  
  # Métodos de instância
  def growth_rate(previous_stat = nil)
    return nil unless previous_stat
    
    return 0 if previous_stat.followers.zero?
    
    ((followers - previous_stat.followers).to_f / previous_stat.followers * 100).round(2)
  end
  
  def formatted_data
    {
      username: username,
      followers: followers,
      following: following,
      posts: posts,
      collected_at: created_at.strftime('%d/%m/%Y %H:%M')
    }
  end
  
  private
  
  def trigger_context_analysis
    # Só disparar se for o primeiro profile_stat OU se passou mais de 7 dias
    existing_context = user.user_profile_context
    return if existing_context&.created_at&.> 7.days.ago
    
    Rails.logger.info "🎯 Disparando análise de contexto para user #{user.id}"
    ProfileContextAnalyzerService.call(user)
  end
end