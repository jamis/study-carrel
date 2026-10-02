class Work < ApplicationRecord
  has_many :sections, -> { order(:number) }, dependent: :destroy

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  def name = [ title, edition ].compact_blank.join(" ")
end
