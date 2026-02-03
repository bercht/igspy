# app/controllers/api/scrapings_controller.rb
class Api::ScrapingsController < ApplicationController
  before_action :authenticate_user!

  def status
    @scraping = current_user.scrapings.find(params[:id])
    @analysis = @scraping.scraping_analysis

    render json: {
      status: @scraping.status,
      status_message: status_message_for(@scraping),
      posts_count: @scraping.instagram_posts.count,
      completed: @scraping.completed?,
      failed: @scraping.failed?,
      in_progress: @scraping.in_progress?,
      has_analysis: @analysis.present? && @analysis.analysis_text.present?,
      completed_at: @scraping.completed_at&.strftime("%d/%m/%Y às %H:%M")
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def status_message_for(scraping)
    return scraping.status_message if scraping.status_message.present?

    case scraping.status
    when "pending"            then "Aguardando início..."
    when "fetching"           then "Buscando postagens no Instagram..."
    when "scraped"            then "Posts coletados. Iniciando transcrições..."
    when "transcribing"       then "Transcrindo áudios dos vídeos..."
    when "transcriptions_completed" then "Transcrições prontas. Iniciando análise..."
    when "analyzing"          then "A IA está analisando os dados..."
    when "completed"          then "Análise concluída com sucesso!"
    when "failed", "analysis_failed" then "Erro no processamento."
    else                           "Aguardando..."
    end
  end
end