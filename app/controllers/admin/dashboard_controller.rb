class Admin::DashboardController < Admin::BaseController
  def index
    # Buscar últimas 3 estatísticas do perfil para o gráfico
    @profile_stats = current_user.profile_stats_for_chart
    
    # Verificar se tem dados ou se está carregando
    @loading_profile_data = @profile_stats.empty? && current_user.instagram_profile.present?
  end
end