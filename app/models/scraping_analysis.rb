# app/models/scraping_analysis.rb
class ScrapingAnalysis < ApplicationRecord
  belongs_to :scraping

  # Status possíveis
  STATUSES = {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }.freeze

  validates :analysis_text, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  validates :scraping_id, uniqueness: true

  # Scopes úteis
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: STATUSES[:completed]) }
  scope :failed, -> { where(status: STATUSES[:failed]) }

  # Helpers de status
  def pending?
    status == STATUSES[:pending]
  end

  def processing?
    status == STATUSES[:processing]
  end

  def completed?
    status == STATUSES[:completed]
  end

  def failed?
    status == STATUSES[:failed]
  end
end