class TriggerAnalysisJob < ApplicationJob
  queue_as :default

  def perform(scraping_id)
    scraping = Scraping.find(scraping_id)
    
    Rails.logger.info "🚀 [TriggerAnalysisJob] Iniciando análise para scraping #{scraping.id}"
    
    # Verificar se todas as transcrições realmente completaram
    total_videos = scraping.instagram_posts.where.not(video_url: nil).count
    completed = scraping.instagram_posts
                        .where(transcription_status: 'completed')
                        .where.not(video_url: nil)
                        .count
    
    unless completed == total_videos && total_videos > 0
      Rails.logger.warn "⚠️ [TriggerAnalysisJob] Transcrições incompletas: #{completed}/#{total_videos}"
      return
    end
    
    Rails.logger.info "✅ [TriggerAnalysisJob] Todas transcrições OK. Disparando análise..."
    
    # Disparar análise no n8n (mesmo endpoint que antes, mas agora com transcrições)
    # O n8n vai buscar os posts do DB que agora têm transcrições completas
    
    callback_url = Rails.application.routes.url_helpers.analysis_completed_url(
      scraping_id: scraping.scraping_id,
      host: ENV['APP_HOST'] || 'apps.curt.com.br',
      protocol: 'https'
    )
    
    n8n_webhook_url = ENV['N8N_ANALYSIS_WEBHOOK_URL'] || 
                      'https://n8n.srv1027542.hstgr.cloud/webhook/trigger-analysis'
    
    payload = {
      scrapingId: scraping.scraping_id,
      scrapingRecordId: scraping.id,
      userId: scraping.user_id,
      callbackUrl: callback_url,
      totalPosts: scraping.instagram_posts.count,
      totalTranscriptions: total_videos
    }
    
    begin
      response = HTTParty.post(
        n8n_webhook_url,
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 10
      )
      
      if response.success?
        Rails.logger.info "✅ [TriggerAnalysisJob] Análise disparada com sucesso"
        
        scraping.update(
          status: 'analyzing',
          metadata: (scraping.metadata || {}).merge(
            analysis_triggered_at: Time.current
          )
        )
      else
        Rails.logger.error "❌ [TriggerAnalysisJob] Erro ao disparar análise: #{response.code}"
        
        scraping.update(
          status: 'analysis_failed',
          error_message: "Failed to trigger analysis: #{response.code}"
        )
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ [TriggerAnalysisJob] Exceção: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      scraping.update(
        status: 'analysis_failed',
        error_message: e.message
      )
    end
  end
end