# app/jobs/daily_profile_update_job.rb
class DailyProfileUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🌙 [DailyProfileUpdateJob] Iniciando atualização diária de perfis às #{Time.current}"
    
    # Buscar todos os usuários que têm instagram_profile configurado
    users_with_instagram = User.where.not(instagram_profile: [nil, ''])
    
    Rails.logger.info "📊 [DailyProfileUpdateJob] #{users_with_instagram.count} usuários com perfil do Instagram"
    
    users_with_instagram.find_each do |user|
      begin
        Rails.logger.info "🚀 Disparando coleta para user #{user.id} (#{user.email})"
        
        # Disparar job de coleta (mesmo usado no cadastro)
        CollectProfileDataJob.perform_later(user.id)
        
      rescue StandardError => e
        Rails.logger.error "❌ Erro ao processar user #{user.id}: #{e.message}"
      end
    end
    
    Rails.logger.info "✅ [DailyProfileUpdateJob] Atualização diária concluída"
  end
end