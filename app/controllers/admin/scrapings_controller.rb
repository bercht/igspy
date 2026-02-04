class Admin::ScrapingsController < Admin::BaseController
  def index
    @scrapings = current_user.scrapings.order(created_at: :desc)
  end

  def show
    @scraping = current_user.scrapings.find(params[:id])
    @analysis = @scraping.scraping_analysis
  end

  def destroy
    @scraping = current_user.scrapings.find(params[:id])
    @scraping.destroy
    redirect_to admin_scrapings_path, notice: "Análise deletada com sucesso."
  end
end
