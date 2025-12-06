class Admin::IgspyController < Admin::BaseController
  def show
    @recent_scrapings = current_user.scrapings.recent.limit(5)
  end

  def create
    # Cria registro de scraping
    scraping = current_user.scrapings.create!(
      profile_url: igspy_params[:igspy_profile_url],
      results_limit: igspy_params[:igspy_results_limit],
      status: Scraping::STATUSES[:pending],
      status_message: "Aguardando início...",
      scraping_id: Time.current.to_i,
      started_at: Time.current
    )

    # Envia para n8n
    result = IgspyWebhookService.call(scraping, current_user)
    
    if result[:success]
      flash[:notice] = "Scraping iniciado! ID: #{scraping.scraping_id}"
      redirect_to admin_scraping_path(scraping)
    else
      scraping.update!(
        status: Scraping::STATUSES[:failed],
        status_message: "Erro ao iniciar: #{result[:error]}"
      )
      flash.now[:alert] = "Erro ao enviar dados: #{result[:error]}"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def igspy_params
    params.permit(:igspy_profile_url, :igspy_results_limit)
  end
end