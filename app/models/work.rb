class Work < ApplicationRecord
  belongs_to :collection, optional: true
  belongs_to :user, optional: true # set for a user's own text, which only they can see; nil for the bundled library
  has_many :sections, -> { order(:number) }, dependent: :destroy

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }
  scope :bundled, -> { where(user_id: nil) }

  # Every work a user may see: the bundled library and their own texts. All lookups of works, sections and units a
  # request names go through this (or Unit.visible_to), so another user's text is simply not found.
  def self.visible_to(user) = where(user_id: [ nil, user&.id ].uniq)

  # Neighbors in library order: within the collection, then on into the neighboring collection under
  # the same parent (Malachi into Matthew), but never out of a top-level collection.
  def next_work
    siblings.where("position > :p OR (position = :p AND id > :i)", p: position, i: id).first || collection&.work_after
  end

  def previous_work
    siblings.reorder(position: :desc, id: :desc).where("position < :p OR (position = :p AND id < :i)", p: position, i: id).first ||
      collection&.work_before
  end

  # Every work's id in library order: the top-level collections in turn, each collection's own works before its child
  # collections' (as Collection#first_work reads), then the works in no collection. Positions only order siblings.
  def self.ids_in_library_order
    works = ordered.pluck(:id, :collection_id).group_by(&:last)
    collections = Collection.ordered.pluck(:id, :parent_id).group_by(&:last)
    inside = ->(id) { works.fetch(id, []).map(&:first) + collections.fetch(id, []).flat_map { inside.(it.first) } }
    collections.fetch(nil, []).flat_map { inside.(it.first) } + works.fetch(nil, []).map(&:first)
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

  # Prose is read a sentence at a time; each sentence belongs to a group (a paragraph, a thought) named by group_name.
  def sentences? = unit_name == "sentence"

  def own_text? = user_id.present?

  # Deletes a user's own text, which must have nothing hanging off it (see UserTextsController#destroy).
  def remove!
    transaction do
      units = Unit.joins(:section).where(sections: { work_id: id })
      Unit.unindex_search(units.pluck(:id))
      Visit.where(unit_id: units.select(:id)).delete_all
      Focus.where(last_unit_id: units.select(:id)).update_all(last_unit_id: nil)
      Unit.where(id: units.select(:id)).delete_all
      sections.delete_all
      delete
    end
  end

  # Whether anything of the user's is attached to this text: a note in any focus, or a keep.
  def annotated?
    units = Unit.joins(:section).where(sections: { work_id: id }).select(:id)
    Note.where(unit_id: units).exists? || Keep.where(unit_id: units).exists?
  end

  private

  def siblings = collection ? collection.works : Work.none
end
