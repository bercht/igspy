# app/controllers/admin/conversations_controller.rb
class Admin::ConversationsController < Admin::BaseController
  before_action :set_conversation, only: [:show, :upload_file]

  def show
    @messages = @conversation.messages.recent
    @scraping = @conversation.scraping
    @analysis = @scraping.scraping_analysis
  end

  def upload_file
    unless params[:file].present?
      render json: { error: "Nenhum arquivo enviado" }, status: :unprocessable_entity
      return
    end

    file = params[:file]
    
    # Validar tipo de arquivo
    allowed_types = %w[text/plain text/csv application/json image/png image/jpeg]
    unless allowed_types.include?(file.content_type)
      render json: { error: "Tipo de arquivo não permitido" }, status: :unprocessable_entity
      return
    end

    # Fazer upload para OpenAI
    result = OpenaiFileUploadService.call(file, @conversation)
    
    if result[:success]
      render json: { 
        success: true, 
        file_id: result[:file_id],
        filename: result[:filename]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Upload error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_conversation
    scraping = current_user.scrapings.find(params[:id])
    
    # Inicializar conversa se não existir
    @conversation = scraping.conversation || ConversationInitializerService.call(scraping)
    
    unless @conversation
      redirect_to admin_scraping_path(scraping), alert: "Erro ao inicializar conversa"
      return
    end
    
    @scraping = scraping
    @analysis = scraping.scraping_analysis
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_scrapings_path, alert: "Scraping não encontrado"
  end
end