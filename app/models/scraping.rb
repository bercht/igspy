# app/models/scraping.rb
class Scraping < ApplicationRecord
  # Constante de status possíveis
  STATUSES = %w[
    pending
    scraping
    scraped
    transcribing
    transcriptions_completed
    analyzing
    completed
    failed
    analysis_failed
  ].freeze
  
  belongs_to :user
  has_many :instagram_posts, dependent: :destroy
  has_one :scraping_analysis, class_name: 'ScrapingAnalysis', dependent: :destroy
  has_one :conversation, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }
  
  # Status possíveis:
  # - pending: aguardando processamento
  # - scraping: Apify está coletando dados
  # - scraped: dados coletados, posts salvos
  # - transcribing: transcrições em andamento (novo!)
  # - transcriptions_completed: todas transcrições prontas (novo!)
  # - analyzing: IA está analisando
  # - completed: tudo concluído
  # - failed: erro em alguma etapa
  # - analysis_failed: erro específico na análise
  
  validates :status, presence: true
  validates :scraping_id, presence: true, uniqueness: true
  
  # Scopes úteis
  scope :with_pending_transcriptions, -> {
    joins(:instagram_posts)
      .where(instagram_posts: { transcription_status: 'pending' })
      .where.not(instagram_posts: { video_url: nil })
      .distinct
  }
  
  scope :ready_for_analysis, -> {
    where(status: 'transcriptions_completed')
  }
  
  # Verificar se todas as transcrições completaram
  def all_transcriptions_completed?
    total_videos = instagram_posts.where.not(video_url: nil).count
    return true if total_videos.zero? # Sem vídeos = não precisa transcrever
    
    completed = instagram_posts
                  .where(transcription_status: 'completed')
                  .where.not(video_url: nil)
                  .count
    
    completed == total_videos
  end
  
  # Progresso das transcrições (0.0 a 1.0)
  def transcription_progress
    total_videos = instagram_posts.where.not(video_url: nil).count
    return 1.0 if total_videos.zero?
    
    completed = instagram_posts
                  .where(transcription_status: 'completed')
                  .where.not(video_url: nil)
                  .count
    
    completed.to_f / total_videos
  end
  
  # Status legível das transcrições
  def transcription_status_summary
    total = instagram_posts.where.not(video_url: nil).count
    completed = instagram_posts.where(transcription_status: 'completed').where.not(video_url: nil).count
    pending = instagram_posts.where(transcription_status: 'pending').where.not(video_url: nil).count
    processing = instagram_posts.where(transcription_status: 'processing').where.not(video_url: nil).count
    error = instagram_posts.where(transcription_status: 'error').where.not(video_url: nil).count
    
    {
      total: total,
      completed: completed,
      pending: pending,
      processing: processing,
      error: error,
      progress_percent: (transcription_progress * 100).round(1)
    }
  end

  # Verificar se está completo
  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed' || status == 'analysis_failed'
  end

  def in_progress?
    %w[pending scraping scraped transcribing transcriptions_completed analyzing].include?(status)
  end

  def pending?
    status == 'pending'
  end

  def analyzing?
    status == 'analyzing'
  end
end