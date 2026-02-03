# app/controllers/api/profile_stats_controller.rb
class Api::ProfileStatsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user_id = params[:userId]
    profile_data = params[:profileData]

    Rails.logger.info "📊 Recebendo dados do perfil para user #{user_id}"

    user = User.find_by(id: user_id)

    unless user
      Rails.logger.error "❌ Usuário não encontrado: #{user_id}"
      return render json: { error: 'User not found' }, status: :not_found
    end

    # Extrair latestPosts separado para salvar no metadata
    latest_posts = profile_data['latestPosts'] || []

    # Resumir posts para metadata (sem URLs enormes de imagens)
    posts_summary = latest_posts.first(10).map do |post|
      {
        id: post['id'],
        type: post['type'],
        timestamp: post['timestamp'],
        likes_count: post['likesCount'],
        comments_count: post['commentsCount'],
        video_view_count: post['videoViewCount'],
        hashtags: post['hashtags'],
        url: post['url']
      }
    end

    profile_stat = user.profile_stats.create!(
      username: profile_data['username'],
      full_name: profile_data['fullName'],
      biography: profile_data['biography'],
      followers: profile_data['followersCount'] || 0,
      following: profile_data['followsCount'] || 0,
      posts: profile_data['postsCount'] || 0,
      profile_url: profile_data['url'],
      profile_image_url: profile_data['profilePicUrl'],
      is_private: profile_data['private'] || false,
      metadata: {
        highlight_reel_count: profile_data['highlightReelCount'],
        is_business_account: profile_data['isBusinessAccount'],
        is_verified: profile_data['verified'],
        external_url: profile_data['externalUrl'],
        latest_posts: posts_summary
      }
    )

    Rails.logger.info "✅ ProfileStat criado: #{profile_stat.id} | followers=#{profile_stat.followers} | following=#{profile_stat.following} | posts=#{profile_stat.posts}"

    ProfileStat.keep_latest(user, 30)

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
