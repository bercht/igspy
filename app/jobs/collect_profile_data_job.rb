require 'net/http'
require 'uri'
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
      uri = URI(n8n_webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['X-N8N-Token'] = ENV['N8N_WEBHOOK_TOKEN'] if ENV['N8N_WEBHOOK_TOKEN']
      request.body = payload.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info "✅ [CollectProfileDataJob] Coleta disparada com sucesso"
      else
        Rails.logger.error "❌ [CollectProfileDataJob] Erro: #{response.code} - #{response.body}"
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