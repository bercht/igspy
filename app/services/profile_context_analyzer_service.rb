# app/services/profile_context_analyzer_service.rb
class ProfileContextAnalyzerService
  require 'net/http'
  require 'uri'
  
  def self.call(user)
    new(user).call
  end
  
  def initialize(user)
    @user = user
  end
  
  def call
    # Criar ou atualizar registro de contexto com status processing
    context = @user.user_profile_context
    
    if context
      context.update!(status: 'processing')
    else
      context = @user.create_user_profile_context!(status: 'processing')
    end
    
    # Buscar último profile_stat
    profile_stat = @user.latest_profile_stat
    
    unless profile_stat
      context.update!(status: 'failed', full_analysis: 'Dados do perfil não disponíveis')
      return { success: false, error: 'No profile data available' }
    end
    
    # Preparar payload para n8n
    payload = {
      userId: @user.id,
      contextId: context.id,
      profileData: {
        username: profile_stat.username,
        biography: profile_stat.biography,
        latestPosts: profile_stat.metadata['latest_posts'] || []
      },
      callbackUrl: callback_url
    }
    
    # Disparar webhook n8n
    send_to_n8n(payload)
    
    { success: true, context_id: context.id }
    
  rescue StandardError => e
    Rails.logger.error "❌ ProfileContextAnalyzerService: #{e.message}"
    context&.update!(status: 'failed', full_analysis: e.message)
    { success: false, error: e.message }
  end
  
  private
  
  def send_to_n8n(payload)
    webhook_url = ENV['N8N_PROFILE_CONTEXT_WEBHOOK_URL'] ||
                  'https://n8n.srv1027542.hstgr.cloud/webhook/profile-context-analysis'
    
    uri = URI(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['X-N8N-Token'] = ENV['N8N_WEBHOOK_TOKEN'] if ENV['N8N_WEBHOOK_TOKEN']
    request.body = payload.to_json
    
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise "n8n returned #{response.code}: #{response.body}"
    end
    
    Rails.logger.info "✅ Profile context analysis dispatched for user #{@user.id}"
  end
  
  def callback_url
    Rails.application.routes.url_helpers.api_profile_context_url(
      host: ENV['APP_HOST'] || 'apps.curt.com.br',
      protocol: 'https'
    )
  end
end