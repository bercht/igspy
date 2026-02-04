class IgspyWebhookService
  require "net/http"
  require "uri"
  require "json"

  def self.call(scraping, user)
    new(scraping, user).call
  end

  def initialize(scraping, user)
    @scraping = scraping
    @user = user
  end

  def call
    webhook_url = ENV.fetch("N8N_WEBHOOK_URL")

    begin
      uri = URI.parse(webhook_url)
      
      Rails.logger.info "=== Igspy Webhook ==="
      Rails.logger.info "Scraping ID: #{@scraping.scraping_id}"
      Rails.logger.info "URL: #{webhook_url}"
      Rails.logger.info "Payload: #{payload.to_json}"
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.request_uri, { 
        "Content-Type" => "application/json",
        "User-Agent" => "Igspy-Rails/1.0"
      })
      request.body = payload.to_json

      Rails.logger.info "Enviando requisição..."
      response = http.request(request)
      Rails.logger.info "Response code: #{response.code}"
      Rails.logger.info "Response body: #{response.body}"

      if response.code.to_i.between?(200, 299)
        { success: true, response: response.body }
      else
        { success: false, error: "HTTP #{response.code}: #{response.message}" }
      end
    rescue Timeout::Error => e
      Rails.logger.error "Timeout error: #{e.message}"
      { success: false, error: "Timeout ao conectar com n8n" }
    rescue StandardError => e
      Rails.logger.error "Error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: "#{e.class}: #{e.message}" }
    end
  end

  private

  def payload
    # Buscar contexto do perfil (se existir)
    context = @user.user_profile_context
    
    profile_context = if context&.completed?
      {
        niche: context.detected_niche,
        audience: context.detected_audience,
        tone: context.communication_tone,
        themes: context.frequent_themes,
        fullAnalysis: context.full_analysis
      }
    else
      nil
    end
    
    {
      scrapingId: @scraping.scraping_id,
      scrapingRecordId: @scraping.id,
      userId: @user.id,
      urls: [ @scraping.profile_url ],
      resultsLimit: @scraping.results_limit,
      callbackUrl: callback_url,
      profileContext: profile_context,
      # API Keys e preferências
      preferredChatApi: @user.preferred_chat_api || 'none',
      anthropicApiKey: @user.anthropic_api_key
    }
  end

  def callback_url
    # URL para o n8n enviar callbacks de progresso
    "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/api/callbacks"
  end
end