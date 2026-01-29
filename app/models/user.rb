class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :scrapings, dependent: :destroy

  # Validações para API keys (opcional - permite vazio)
  validates :manus_api_key, format: { with: /\A[a-zA-Z0-9_-]*\z/, allow_blank: true }, if: -> { manus_api_key.present? }
  validates :anthropic_api_key, format: { with: /\A[a-zA-Z0-9_-]*\z/, allow_blank: true }, if: -> { anthropic_api_key.present? }
end