class ScrapingUsageService
  def self.current_usage(user)
    new(user).current_usage
  end

  def self.increment(user)
    new(user).increment
  end

  def initialize(user)
    @user = user
  end

  def current_usage
    usage_record = find_or_create_usage_record
    usage_record.count
  end

  def increment
    usage_record = find_or_create_usage_record
    usage_record.increment!(:count)
  end

  private

  def find_or_create_usage_record
    period = Date.today.beginning_of_month
    @user.scraping_usages.find_or_create_by!(period: period)
  end
end