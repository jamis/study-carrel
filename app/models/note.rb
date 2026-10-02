class Note < ApplicationRecord
  belongs_to :unit
  belongs_to :focus

  validates :body, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
