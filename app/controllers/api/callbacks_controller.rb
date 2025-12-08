# app/controllers/api/callbacks_controller.rb
class Api::CallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_n8n_token

  def create
    scraping = Scraping.find_by(scraping_id: callback_params[:scraping_id])

    unless scraping
      render json: { error: "Scraping não encontrado" }, status: :not_found
      return
    end

    # Atualiza status
    scraping.update!(
      status: callback_params[:status],
      status_message: callback_params[:message]
    )

    # Se completou, salva timestamp E processa o JSON do Apify
    if scraping.completed?
      scraping.update!(completed_at: Time.current)
      process_apify_data(scraping)
    end

    render json: { success: true, scraping_id: scraping.scraping_id }
  rescue StandardError => e
    Rails.logger.error "Callback error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def callback_params
    params.permit(:scraping_id, :status, :message, apify_data: [])
  end

  def verify_n8n_token
    token = request.headers["X-N8N-Token"]
    expected_token = ENV.fetch("N8N_CALLBACK_TOKEN", "secret_token_123")

    unless token == expected_token
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def process_apify_data(scraping)
    apify_data = callback_params[:apify_data]
    
    return unless apify_data.present?

    processor = ApifyJsonProcessorService.new(scraping, apify_data)
    
    if processor.call
      Rails.logger.info "Successfully processed #{apify_data.length} posts for scraping #{scraping.id}"
    else
      Rails.logger.error "ApifyJsonProcessor errors: #{processor.errors.join(', ')}"
      scraping.update!(
        status_message: "Dados processados com erros: #{processor.errors.first}"
      )
    end
  end
end