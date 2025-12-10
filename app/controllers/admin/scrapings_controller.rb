class Admin::ScrapingsController < Admin::BaseController
  def index
    @scrapings = current_user.scrapings
  end

  def show
    @scraping = current_user.scrapings.find(params[:id])
    @analysis = @scraping.scraping_analysis
  end
end
