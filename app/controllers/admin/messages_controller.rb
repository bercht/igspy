# app/controllers/admin/messages_controller.rb
class Admin::MessagesController < Admin::BaseController
  before_action :set_conversation

  def create
    # Criar mensagem do usuário
    user_message = @conversation.messages.create!(
      role: "user",
      content: message_params[:content]
    )

    # Anexar arquivos se houver
    if message_params[:file_ids].present?
      message_params[:file_ids].each do |file_data|
        user_message.message_attachments.create!(
          file_id: file_data[:file_id],
          filename: file_data[:filename],
          content_type: file_data[:content_type],
          file_size: file_data[:file_size]
        )
      end
    end

    # Enviar para OpenAI e receber resposta
    result = OpenaiAssistantService.call(@conversation, user_message)

    if result[:success]
      # Criar mensagem do assistant
      assistant_message = @conversation.messages.create!(
        role: "assistant",
        content: result[:content],
        message_id: result[:message_id],
        metadata: result[:metadata] || {}
      )

      render json: {
        success: true,
        user_message: format_message(user_message),
        assistant_message: format_message(assistant_message)
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Message creation error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_conversation
    scraping = current_user.scrapings.find(params[:conversation_id])
    @conversation = scraping.conversation
    
    unless @conversation
      render json: { error: "Conversa não encontrada" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Scraping não encontrado" }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content, file_ids: [:file_id, :filename, :content_type, :file_size])
  end

  def format_message(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      created_at: message.created_at.strftime("%H:%M"),
      attachments: message.message_attachments.map do |attachment|
        {
          filename: attachment.filename,
          file_size: attachment.file_size_human
        }
      end
    }
  end
end