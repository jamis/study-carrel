class Collection < ApplicationRecord
  has_many :works, -> { order(:position, :id) }, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }

  def to_param = slug
end
