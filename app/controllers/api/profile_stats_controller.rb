# app/controllers/api/profile_stats_controller.rb
class Api::ProfileStatsController < ApplicationController
  # Desabilitar CSRF para webhooks externos
  skip_before_action :verify_authenticity_token
  
  # Endpoint para receber dados do perfil do n8n
  def create
    user_id = params[:userId]
    profile_data = params[:profileData]
    
    Rails.logger.info "📊 Recebendo dados do perfil para user #{user_id}"
    
    user = User.find_by(id: user_id)
    
    unless user
      Rails.logger.error "❌ Usuário não encontrado: #{user_id}"
      return render json: { error: 'User not found' }, status: :not_found
    end
    
    # Criar registro de ProfileStat
    profile_stat = user.profile_stats.create!(
      username: profile_data['username'],
      full_name: profile_data['fullName'],
      biography: profile_data['biography'],
      followers: profile_data['followers'] || 0,
      following: profile_data['following'] || 0,
      posts: profile_data['posts'] || 0,
      profile_url: profile_data['url'],
      profile_image_url: profile_data['image'],
      is_private: profile_data['is_private'] || false,
      metadata: profile_data.except('username', 'fullName', 'biography', 'followers', 'following', 'posts', 'url', 'image', 'is_private')
    )
    
    Rails.logger.info "✅ ProfileStat criado: #{profile_stat.id}"
    
    # Manter apenas as 3 últimas
    ProfileStat.keep_latest(user, 3)
    
    render json: { 
      success: true, 
      profile_stat_id: profile_stat.id,
      message: 'Profile data saved successfully' 
    }
    
  rescue StandardError => e
    Rails.logger.error "❌ Erro ao salvar profile stat: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: { error: e.message }, status: :internal_server_error
  end
end