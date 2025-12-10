# app/services/conversation_initializer_service.rb
class ConversationInitializerService
  require "net/http"
  require "uri"

  def self.call(scraping)
    new(scraping).call
  end

  def initialize(scraping)
    @scraping = scraping
    @api_key = ENV.fetch("OPENAI_API_KEY")
  end

  def call
    # Verificar se já existe conversa
    return @scraping.conversation if @scraping.conversation.present?

    # Criar thread na OpenAI
    thread_response = create_thread
    return nil unless thread_response[:success]

    # Criar registro de conversa no banco
    conversation = @scraping.create_conversation!(
      thread_id: thread_response[:thread_id],
      status: "active",
      metadata: {
        assistant_id: @scraping.scraping_analysis.assistant_id,
        created_by_service: true
      }
    )

    Rails.logger.info "Conversation created: #{conversation.id} with thread: #{conversation.thread_id}"
    conversation
  rescue StandardError => e
    Rails.logger.error "Conversation initialization error: #{e.message}"
    nil
  end

  private

  def create_thread
    uri = URI.parse("https://api.openai.com/v1/threads")
    
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request["OpenAI-Beta"] = "assistants=v2"
    
    request.body = {}.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      data = JSON.parse(response.body)
      { success: true, thread_id: data["id"] }
    else
      Rails.logger.error "Failed to create thread: #{response.body}"
      { success: false, error: response.body }
    end
  end
end