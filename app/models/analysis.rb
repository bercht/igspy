class Analysis < ApplicationRecord
  belongs_to :scraping
  
  validates :scraping_id, presence: true, uniqueness: true
end