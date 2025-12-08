# app/models/instagram_post.rb
class InstagramPost < ApplicationRecord
  belongs_to :scraping

  # Validações básicas
  validates :instagram_id, presence: true, uniqueness: true
  validates :post_type, presence: true

  # Enums para status de transcrição
  enum transcription_status: {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, _prefix: :transcription

  # Scopes úteis
  scope :videos, -> { where(post_type: "Video") }
  scope :images, -> { where(post_type: "Image") }
  scope :sidecar, -> { where(post_type: "Sidecar") }
  scope :recent, -> { order(posted_at: :desc) }
  scope :popular, -> { order(likes_count: :desc) }
  scope :with_transcription, -> { where.not(transcription: nil) }
  scope :needs_transcription, -> { videos.transcription_pending }

  # Métodos auxiliares
  def engagement_rate
    return 0 if video_view_count.to_i.zero?
    ((likes_count + comments_count).to_f / video_view_count * 100).round(2)
  end

  def has_video?
    video_url.present?
  end

  def has_audio?
    audio_url.present?
  end

  def video?
    post_type == "Video"
  end

  def image?
    post_type == "Image"
  end

  def sidecar?
    post_type == "Sidecar"
  end
end