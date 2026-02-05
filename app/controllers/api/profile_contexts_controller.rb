# app/controllers/api/profile_contexts_controller.rb
class Api::ProfileContextsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def create
    context_id = params[:contextId] || params[:context_id]
    analysis_result = params[:analysisResult] || params[:analysis_result] || params[:analysis]
    
    Rails.logger.info "📥 Recebendo callback de análise de contexto: #{context_id}"
    
    unless context_id.present? && analysis_result.present?
      Rails.logger.error "❌ Profile context callback missing data: context_id=#{context_id.inspect} analysis_result=#{analysis_result.class}"
      render json: { error: "Missing contextId or analysisResult" }, status: :unprocessable_entity
      return
    end
    
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
