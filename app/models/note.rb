class Note < ApplicationRecord
  belongs_to :unit
  belongs_to :focus

  has_rich_text :content

  validates :content, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
