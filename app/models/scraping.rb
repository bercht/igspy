class Scraping < ApplicationRecord
  belongs_to :user

  # Status possíveis
  STATUSES = {
    pending: "pending",           # Aguardando início
    fetching: "fetching",         # Buscando postagens
    processing: "processing",     # Processando dados
    completed: "completed",       # Finalizado com sucesso
    failed: "failed"              # Falhou
  }.freeze

  validates :profile_url, presence: true
  validates :results_limit, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES.values }

  # Scopes úteis
  scope :recent, -> { order(created_at: :desc) }
  scope :in_progress, -> { where(status: [STATUSES[:pending], STATUSES[:fetching], STATUSES[:processing]]) }
  scope :completed, -> { where(status: STATUSES[:completed]) }

  # Helpers de status
  def pending?
    status == STATUSES[:pending]
  end

  def in_progress?
    [STATUSES[:fetching], STATUSES[:processing]].include?(status)
  end

  def completed?
    status == STATUSES[:completed]
  end

  def failed?
    status == STATUSES[:failed]
  end
end