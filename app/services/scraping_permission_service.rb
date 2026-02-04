class ScrapingPermissionService
  def self.check(user)
    new(user).check
  end

  def initialize(user)
    @user = user
  end

  def check
    # 1. Plano ativo
    return { allowed: false, reason: :no_active_plan } unless @user.subscribed?

    # 2. Limite de scrapings salvos
    if saved_scrapings_limit_reached?
      return { allowed: false, reason: :saved_scrapings_limit_reached }
    end

    # 3. Limite mensal
    if monthly_limit_reached?
      return { allowed: false, reason: :monthly_limit_reached }
    end

    { allowed: true, reason: nil }
  end

  private

  def saved_scrapings_limit_reached?
    @user.scrapings.where(status: ["pending", "completed", "analyzing"]).count >= 3
  end

  def monthly_limit_reached?
    usage = ScrapingUsageService.current_usage(@user)
    usage >= 10
  end
end