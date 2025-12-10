# app/services/openai_file_upload_service.rb
class OpenaiFileUploadService
  require "net/http"
  require "uri"

  def self.call(file, conversation)
    new(file, conversation).call
  end

  def initialize(file, conversation)
    @file = file
    @conversation = conversation
    @api_key = ENV.fetch("OPENAI_API_KEY")
  end

  def call
    # Upload do arquivo para OpenAI
    upload_response = upload_to_openai
    return upload_response unless upload_response[:success]

    file_id = upload_response[:file_id]

    # Adicionar arquivo ao Vector Store existente
    vector_store_id = @conversation.scraping.scraping_analysis.vector_store_id
    add_response = add_to_vector_store(file_id, vector_store_id)
    
    return add_response unless add_response[:success]

    {
      success: true,
      file_id: file_id,
      filename: @file.original_filename
    }
  rescue StandardError => e
    Rails.logger.error "OpenAI file upload error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def upload_to_openai
    uri = URI.parse("https://api.openai.com/v1/files")
    
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    
    # Criar multipart form data
    boundary = "----WebKitFormBoundary#{SecureRandom.hex(16)}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    
    body = []
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"purpose\"\r\n\r\n"
    body << "assistants\r\n"
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{@file.original_filename}\"\r\n"
    body << "Content-Type: #{@file.content_type}\r\n\r\n"
    body << @file.read
    body << "\r\n--#{boundary}--\r\n"
    
    request.body = body.join

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      data = JSON.parse(response.body)
      { success: true, file_id: data["id"] }
    else
      { success: false, error: "Upload falhou: #{response.body}" }
    end
  end

  def add_to_vector_store(file_id, vector_store_id)
    uri = URI.parse("https://api.openai.com/v1/vector_stores/#{vector_store_id}/files")
    
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request["OpenAI-Beta"] = "assistants=v2"
    
    request.body = { file_id: file_id }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i.between?(200, 299)
      { success: true }
    else
      { success: false, error: "Erro ao adicionar ao Vector Store: #{response.body}" }
    end
  end
end