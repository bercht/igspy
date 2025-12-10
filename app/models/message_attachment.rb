# app/models/message_attachment.rb
class MessageAttachment < ApplicationRecord
  belongs_to :message

  validates :file_id, presence: true
  validates :filename, presence: true

  def file_size_human
    return "0 B" if file_size.nil? || file_size.zero?

    units = %w[B KB MB GB]
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024.0
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end
end