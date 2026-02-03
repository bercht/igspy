class Subscription < ApplicationRecord
  belongs_to :user

  # Enum para status da assinatura
  enum status: {
    incomplete: 'incomplete',
    incomplete_expired: 'incomplete_expired',
    trialing: 'trialing',
    active: 'active',
    past_due: 'past_due',
    canceled: 'canceled',
    unpaid: 'unpaid'
  }

  # Validações
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_price_id, presence: true
  validates :status, presence: true

  # Scopes
  scope :active_subscriptions, -> { where(status: ['active', 'trialing']) }
  scope :expired, -> { where('current_period_end < ?', Time.current) }

  # Métodos auxiliares
  def active?
    ['active', 'trialing'].include?(status)
  end

  def expired?
    current_period_end.present? && current_period_end < Time.current
  end

  def will_cancel?
    cancel_at.present?
  end

  def plan_name
    case stripe_price_id
    when Rails.application.credentials.dig(:stripe, :price_monthly)
      'Mensal'
    when Rails.application.credentials.dig(:stripe, :price_semiannual)
      'Semestral'
    else
      'Desconhecido'
    end
  end
end