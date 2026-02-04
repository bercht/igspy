class DemoScraping < ApplicationRecord
  validates :profile_username, presence: true, uniqueness: true
  validates :profile_data, presence: true
  validates :cached_analysis, presence: true

  def self.fetch_demo
    find_by(profile_username: 'adammosseri')
  end
end