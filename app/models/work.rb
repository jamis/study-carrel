class Work < ApplicationRecord
  belongs_to :collection, optional: true
  has_many :sections, -> { order(:number) }, dependent: :destroy

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }

  def name = [ title, edition ].compact_blank.join(" ")
end
