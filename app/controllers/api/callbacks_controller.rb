class Api::CallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_n8n_token

  def create
    scraping = Scraping.find_by(scraping_id: callback_params[:scraping_id])

    unless scraping
      render json: { error: "Scraping não encontrado" }, status: :not_found
      return
    end

    scraping.update!(
      status: callback_params[:status],
      status_message: callback_params[:message]
    )

    # Se completou, salva o timestamp
    scraping.update!(completed_at: Time.current) if scraping.completed?

    render json: { success: true, scraping_id: scraping.scraping_id }
  rescue StandardError => e
    Rails.logger.error "Callback error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def callback_params
    params.permit(:scraping_id, :status, :message)
  end

  def verify_n8n_token
    # Verificação simples de token
    token = request.headers["X-N8N-Token"]
    expected_token = ENV.fetch("N8N_CALLBACK_TOKEN", "secret_token_123")

    unless token == expected_token
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end