# app/jobs/cleanup_old_analyses_job.rb
class CleanupOldAnalysesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🧹 [CleanupOldAnalysesJob] Iniciando limpeza de análises antigas"
    
    User.find_each do |user|
      cleanup_user_analyses(user)
      cleanup_user_profile_stats(user)
    end
    
    Rails.logger.info "✅ [CleanupOldAnalysesJob] Limpeza concluída"
  end
  
  private
  
  def cleanup_user_analyses(user)
    # Buscar análises do usuário ordenadas por data (mais recentes primeiro)
    analyses = user.scrapings.includes(:scraping_analysis).order(created_at: :desc)
    
    # Pular as 3 primeiras (manter)
    analyses_to_delete = analyses.offset(3)
    
    count = 0
    
    analyses_to_delete.each do |scraping|
      analysis = scraping.scraping_analysis
      
      if analysis
        # Deletar assistant da OpenAI se existir
        delete_openai_assistant(analysis.assistant_id) if analysis.assistant_id.present?
        
        # Deletar vector store da OpenAI se existir
        delete_openai_vector_store(analysis.vector_store_id) if analysis.vector_store_id.present?
        
        # Deletar análise do banco
        analysis.destroy
        count += 1
      end
      
      # Deletar scraping e posts associados
      scraping.destroy
    end
    
    Rails.logger.info "🗑️  User #{user.id}: #{count} análises antigas deletadas" if count > 0
  end
  
  def cleanup_user_profile_stats(user)
    # Usar o método já criado no model
    ProfileStat.keep_latest(user, 3)
  end
  
  def delete_openai_assistant(assistant_id)
    api_key = ENV['OPENAI_API_KEY']
    return unless api_key
    
    uri = URI("https://api.openai.com/v1/assistants/#{assistant_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Delete.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['OpenAI-Beta'] = 'assistants=v2'
    
    response = http.request(request)
    
    if response.code.to_i == 200
      Rails.logger.info "✅ Assistant #{assistant_id} deletado da OpenAI"
    else
      Rails.logger.warn "⚠️  Erro ao deletar assistant #{assistant_id}: #{response.code}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ Erro ao deletar assistant: #{e.message}"
  end
  
  def delete_openai_vector_store(vector_store_id)
    api_key = ENV['OPENAI_API_KEY']
    return unless api_key
    
    uri = URI("https://api.openai.com/v1/vector_stores/#{vector_store_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Delete.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['OpenAI-Beta'] = 'assistants=v2'
    
    response = http.request(request)
    
    if response.code.to_i == 200
      Rails.logger.info "✅ Vector Store #{vector_store_id} deletado da OpenAI"
    else
      Rails.logger.warn "⚠️  Erro ao deletar vector store #{vector_store_id}: #{response.code}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ Erro ao deletar vector store: #{e.message}"
  end
end