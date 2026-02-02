# app/controllers/webhooks/base_controller.rb
module Webhooks
  class BaseController < ApplicationController
    # Desabilitar CSRF para webhooks externos
    skip_before_action :verify_authenticity_token
    
    # Callback do n8n quando todas as transcrições completarem
    def transcriptions_completed
      scraping_id = params[:scrapingId]
      scraping_record_id = params[:scrapingRecordId]
      
      Rails.logger.info "🎉 Webhook: Todas transcrições completadas para scraping #{scraping_id}"
      
      # Buscar o scraping
      scraping = Scraping.find_by(id: scraping_record_id)
      
      unless scraping
        Rails.logger.error "❌ Scraping não encontrado: #{scraping_record_id}"
        return render json: { error: 'Scraping not found' }, status: :not_found
      end
      
      # Verificar se realmente TODAS as transcrições completaram
      total_videos = scraping.instagram_posts.where.not(video_url: nil).count
      completed = scraping.instagram_posts
                          .where(transcription_status: 'completed')
                          .where.not(video_url: nil)
                          .count
      
      Rails.logger.info "📊 Progresso: #{completed}/#{total_videos} transcrições completas"
      
      if completed == total_videos && total_videos > 0
        # Todas completaram! Disparar análise IA
        Rails.logger.info "✅ Disparando análise IA..."
        
        # Atualizar status do scraping
        scraping.update(
          status: 'transcriptions_completed',
          metadata: (scraping.metadata || {}).merge(
            transcriptions_completed_at: Time.current,
            total_transcriptions: total_videos
          )
        )
        
        # Disparar job de análise
        TriggerAnalysisJob.perform_later(scraping.id)
        
        render json: { 
          success: true, 
          message: 'Analysis triggered',
          total_transcriptions: total_videos
        }
      else
        # Ainda faltam transcrições
        Rails.logger.info "⏳ Aguardando mais transcrições..."
        
        render json: { 
          success: true, 
          message: 'Still waiting for transcriptions',
          progress: "#{completed}/#{total_videos}"
        }
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ Erro no webhook: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Health check do webhook
    def health
      render json: { status: 'ok', timestamp: Time.current }
    end
  end
end