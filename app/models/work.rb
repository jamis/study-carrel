class Work < ApplicationRecord
  belongs_to :collection, optional: true
  has_many :sections, -> { order(:number) }, dependent: :destroy

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }

  # Neighbors within the same collection, in library order.
  def next_work
    siblings.where("position > :p OR (position = :p AND id > :i)", p: position, i: id).first
  end

  def previous_work
    siblings.reorder(position: :desc, id: :desc).where("position < :p OR (position = :p AND id < :i)", p: position, i: id).first
  end

  def to_param = slug

  def name = [ title, edition ].compact_blank.join(" ")

  private

  def siblings = collection ? collection.works : Work.none
end
