class Admin::IgspyController < Admin::BaseController
  before_action :check_scraping_permission, only: [:create]

  def show
    @demo_scraping = DemoScraping.fetch_demo
    @recent_scrapings = current_user.scrapings.recent.limit(5)
  end

  def create
    # Cria registro de scraping
    scraping = current_user.scrapings.create!(
      profile_url: igspy_params[:igspy_profile_url],
      results_limit: igspy_params[:igspy_results_limit],
      status: 'pending',
      status_message: "Aguardando início...",
      scraping_id: Time.current.to_i,
      started_at: Time.current
    )
    
    # Incrementa uso mensal
    ScrapingUsageService.increment(current_user)
    
    # Envia para n8n
    result = IgspyWebhookService.call(scraping, current_user)
    
    if result[:success]
      flash[:notice] = "Scraping iniciado! ID: #{scraping.scraping_id}"
      redirect_to admin_scraping_path(scraping)
    else
      scraping.update!(
        status: 'failed',
        status_message: "Erro ao iniciar: #{result[:error]}"
      )
      flash.now[:alert] = "Erro ao enviar dados: #{result[:error]}"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def check_scraping_permission
    permission = ScrapingPermissionService.check(current_user)
    return if permission[:allowed]

    handle_permission_failure(permission[:reason])
  end

  def handle_permission_failure(reason)
    flash_message = case reason
                    when :no_active_plan
                      "Você precisa de um plano ativo para criar análises."
                    when :saved_scrapings_limit_reached
                      "Você atingiu o limite de 3 análises salvas. Exclua uma para continuar."
                    when :monthly_limit_reached
                      period_end = current_user.subscription&.current_period_end&.strftime("%d/%m/%Y") || "em breve"
                      "Você atingiu seu limite de 10 análises mensais. O limite reinicia em #{period_end}."
                    else
                      "Ocorreu um erro desconhecido."
                    end

    respond_to do |format|
      format.html { redirect_to admin_igspy_path, alert: flash_message }
      format.json { render json: { error: flash_message }, status: :forbidden }
    end
  end

  def igspy_params
    params.permit(:igspy_profile_url, :igspy_results_limit)
  end
end