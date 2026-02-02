# app/jobs/collect_profile_data_job.rb
class CollectProfileDataJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    
    Rails.logger.info "📊 [CollectProfileDataJob] Coletando dados para user #{user.id}"
    
    # Normalizar URL do Instagram
    instagram_url = normalize_instagram_url(user.instagram_profile)
    
    unless instagram_url
      Rails.logger.error "❌ [CollectProfileDataJob] URL do Instagram inválida: #{user.instagram_profile}"
      return
    end
    
    # URL do webhook n8n para self_profile_data
    n8n_webhook_url = ENV['N8N_PROFILE_WEBHOOK_URL'] || 
                      'https://n8n.srv1027542.hstgr.cloud/webhook/self-profile-data'
    
    # Callback URL para receber os dados
    callback_url = Rails.application.routes.url_helpers.api_profile_stats_url(
      host: ENV['APP_HOST'] || 'apps.curt.com.br',
      protocol: 'https'
    )
    
    payload = {
      userId: user.id,
      instagramUrl: instagram_url,
      callbackUrl: callback_url
    }
    
    begin
      response = HTTParty.post(
        n8n_webhook_url,
        body: payload.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'X-N8N-Token' => ENV['N8N_WEBHOOK_TOKEN']
        },
        timeout: 10
      )
      
      if response.success?
        Rails.logger.info "✅ [CollectProfileDataJob] Coleta disparada com sucesso"
      else
        Rails.logger.error "❌ [CollectProfileDataJob] Erro: #{response.code}"
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ [CollectProfileDataJob] Exceção: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
  
  private
  
  def normalize_instagram_url(input)
    return nil if input.blank?
    
    # Se já é URL completa
    if input.match?(/^https?:\/\//)
      return input
    end
    
    # Se começa com @, remove
    username = input.gsub(/^@/, '')
    
    # Retorna URL formatada
    "https://www.instagram.com/#{username}/"
  end
end