# app/services/openai_assistant_service.rb
class OpenaiAssistantService
  require "net/http"
  require "uri"

  def self.call(conversation, user_message)
    new(conversation, user_message).call
  end

  def initialize(conversation, user_message)
    @conversation = conversation
    @user_message = user_message
    @api_key = ENV.fetch("OPENAI_API_KEY")
    @thread_id = conversation.thread_id
    @assistant_id = conversation.scraping.scraping_analysis.assistant_id
  end

  def call
    # 1. Adicionar mensagem ao thread
    add_response = add_message_to_thread
    return add_response unless add_response[:success]

    # 2. Executar o assistant (criar run)
    run_response = create_run
    return run_response unless run_response[:success]

    run_id = run_response[:run_id]

    # 3. Polling até completar
    final_run = poll_run_status(run_id)
    return { success: false, error: "Run falhou: #{final_run["status"]}" } unless final_run["status"] == "completed"

    # 4. Recuperar mensagens do thread
    messages_response = get_thread_messages
    return messages_response unless messages_response[:success]

    # Pegar a última mensagem do assistant
    assistant_message = messages_response[:messages].first

    {
      success: true,
      content: assistant_message["content"][0]["text"]["value"],
      message_id: assistant_message["id"],
      metadata: {
        run_id: run_id,
        thread_id: @thread_id
      }
    }
  rescue StandardError => e
    Rails.logger.error "OpenAI Assistant error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def add_message_to_thread
    uri = URI.parse("https://api.openai.com/v1/threads/#{@thread_id}/messages")
    
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request["OpenAI-Beta"] = "assistants=v2"
    
    # Preparar attachments se houver
    attachments = @user_message.message_attachments.map do |attachment|
      {
        file_id: attachment.file_id,
        tools: [{ type: "file_search" }]
      }
    end

    body = {
      role: "user",
      content: @user_message.content
    }
    body[:attachments] = attachments if attachments.any?

    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      { success: true }
    else
      { success: false, error: "Erro ao adicionar mensagem: #{response.body}" }
    end
  end

  def create_run
    uri = URI.parse("https://api.openai.com/v1/threads/#{@thread_id}/runs")
    
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request["OpenAI-Beta"] = "assistants=v2"
    
    request.body = { assistant_id: @assistant_id }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      data = JSON.parse(response.body)
      { success: true, run_id: data["id"] }
    else
      { success: false, error: "Erro ao criar run: #{response.body}" }
    end
  end

  def poll_run_status(run_id, max_attempts = 60)
    attempts = 0
    
    loop do
      attempts += 1
      
      uri = URI.parse("https://api.openai.com/v1/threads/#{@thread_id}/runs/#{run_id}")
      
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["OpenAI-Beta"] = "assistants=v2"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      run_data = JSON.parse(response.body)
      status = run_data["status"]

      Rails.logger.info "Run status: #{status} (attempt #{attempts})"

      return run_data if ["completed", "failed", "cancelled", "expired"].include?(status)

      break if attempts >= max_attempts

      sleep 1
    end

    { "status" => "timeout" }
  end

  def get_thread_messages
    uri = URI.parse("https://api.openai.com/v1/threads/#{@thread_id}/messages?limit=1&order=desc")
    
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["OpenAI-Beta"] = "assistants=v2"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      data = JSON.parse(response.body)
      { success: true, messages: data["data"] }
    else
      { success: false, error: "Erro ao recuperar mensagens: #{response.body}" }
    end
  end
end