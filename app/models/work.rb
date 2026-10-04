class Work < ApplicationRecord
  belongs_to :collection, optional: true
  has_many :sections, -> { order(:number) }, dependent: :destroy

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }

  # Neighbors in library order: within the collection, then on into the neighboring collection under
  # the same parent (Malachi into Matthew), but never out of a top-level collection.
  def next_work
    siblings.where("position > :p OR (position = :p AND id > :i)", p: position, i: id).first || collection&.work_after
  end

  def previous_work
    siblings.reorder(position: :desc, id: :desc).where("position < :p OR (position = :p AND id < :i)", p: position, i: id).first ||
      collection&.work_before
  end

  def to_param = slug

  def short_author = author_short.presence || author

  # The author to show beside the title, unless the title already is the author (Emily Dickinson).
  def byline
    author if author.present? && !title.include?(author)
  end

  def short_byline
    short_author if byline
  end

  def name = [ title, edition ].compact_blank.join(" ")

  private

  def siblings = collection ? collection.works : Work.none
end
