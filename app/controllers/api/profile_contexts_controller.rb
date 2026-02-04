# app/controllers/api/profile_contexts_controller.rb
class Api::ProfileContextsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    context_id = params[:contextId]
    analysis_result = params[:analysisResult]
    
    Rails.logger.info "📥 Recebendo callback de análise de contexto: #{context_id}"
    
    context = UserProfileContext.find(context_id)
    
    context.update!(
      status: 'completed',
      detected_niche: analysis_result['niche'],
      detected_audience: analysis_result['audience'],
      communication_tone: analysis_result['tone'],
      frequent_themes: analysis_result['themes'],
      full_analysis: analysis_result['fullText']
    )
    
    Rails.logger.info "✅ Profile context updated: #{context.id}"
    
    render json: { success: true, context_id: context.id }
    
  rescue StandardError => e
    Rails.logger.error "❌ Profile context callback error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: { error: e.message }, status: :internal_server_error
  end
end