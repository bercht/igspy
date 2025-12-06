class Admin::ScrapingsController < Admin::BaseController
  def index
    @scrapings = current_user.scrapings.recent.page(params[:page]).per(20)
  end

  def show
    @scraping = current_user.scrapings.find(params[:id])
  end
end