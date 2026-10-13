# A user's own grouping of works and collections (Poets I love; the Bible and the Book of Mormon together), to roll
# Random and search in. Private to its owner: it is only ever found through user.shelves, and its works only through
# Work.visible_to(user).
#
# A collection on a shelf brings everything nested under it, now and later. Nothing is on a shelf twice: something
# under a collection on the shelf is on it already, through that collection, and putting a collection on takes in
# anything already there from under it.
class Shelf < ApplicationRecord
  belongs_to :user
  has_many :items, class_name: "ShelfItem", dependent: :delete_all

  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.strip.presence }
  validates :name, presence: true, length: { maximum: 80 }
  validates :description, length: { maximum: 300 }
  before_validation :set_slug, on: :create

  def to_param = slug

  # The work or collection a form names ("work-12", "collection-3"), if the user may see it.
  def self.thing_for(key, user)
    kind, id = key.to_s.split("-", 2)
    case kind
    when "work" then Work.visible_to(user).find_by(id:)
    when "collection" then Collection.find_by(id:)
    end
  end

  def self.key_for(thing) = "#{thing.is_a?(Work) ? "work" : "collection"}-#{thing.id}"

  def collection_ids = items.filter_map(&:collection_id)
  def work_item_ids = items.filter_map(&:work_id)

  # What's on the shelf: its collections in library order, then its works in library order.
  def members
    things = items.includes(:work, :collection).map(&:thing)
    collections = things.grep(Collection).sort_by { |c| chain(c.id).reverse.map { [ positions[it], it ] } }
    order = Work.ids_in_library_order.each_with_index.to_h
    works = things.grep(Work).select { it.user_id.nil? || it.user_id == user_id }.sort_by { order.fetch(it.id, Float::INFINITY) }
    collections + works
  end

  def on?(thing) = (thing.is_a?(Work) ? work_item_ids : collection_ids).include?(thing.id)

  # The collection on this shelf that a work or collection is on it through, if any.
  def via(thing)
    id = chain(parent_id_of(thing)).find { collection_ids.include?(it) }
    Collection.find(id) if id
  end

  # The ids of the collections a work or collection sits in, innermost first.
  def ancestor_ids(thing) = chain(parent_id_of(thing))

  def holds?(thing) = on?(thing) || chain(parent_id_of(thing)).intersect?(collection_ids)

  # What's on the shelf from under a collection, which putting the collection on would take in.
  def under(collection) = members.select { inside?(it, collection) }

  def put!(thing)
    return if holds?(thing)

    transaction do
      under(thing).each { take!(it) } if thing.is_a?(Collection)
      items.create!(item_key(thing))
    end
    items.reset
  end

  def take!(thing)
    items.where(item_key(thing)).delete_all
    items.reset
  end

  # Sets what's on the shelf (the editor's save), leaving out anything a collection among them already brings.
  def replace!(things)
    things = things.compact.uniq
    kept = things.reject { |thing| things.any? { it.is_a?(Collection) && inside?(thing, it) } }
    transaction do
      items.delete_all
      kept.each { items.create!(item_key(it)) }
    end
    items.reset
  end

  # Ids of every work on the shelf the owner can see, directly or under one of its collections.
  def work_ids
    nested = collection_ids.flat_map { subtree(it) }
    Work.visible_to(user).where(id: work_item_ids).or(Work.visible_to(user).where(collection_id: nested)).pluck(:id)
  end

  private

  def item_key(thing) = thing.is_a?(Work) ? { work_id: thing.id } : { collection_id: thing.id }

  def parent_id_of(thing) = thing.is_a?(Work) ? thing.collection_id : thing.parent_id

  # Whether a work or collection is nested anywhere under a collection (a collection is not inside itself).
  def inside?(thing, collection) = thing != collection && chain(parent_id_of(thing)).include?(collection.id)

  # A collection's id and its ancestors' ids, innermost first.
  def chain(id)
    ids = []
    while id && ids.exclude?(id)
      ids << id
      id = parents[id]
    end
    ids
  end

  def subtree(id) = parents.keys.select { chain(it).include?(id) }

  def parents = @parents ||= Collection.pluck(:id, :parent_id).to_h
  def positions = @positions ||= Collection.pluck(:id, :position).to_h

  # A random suffix, as for a user's own text, so an address never gives away what another user calls a shelf.
  def set_slug
    base = name.to_s.parameterize.presence || "shelf"
    self.slug = loop do
      slug = "#{base}-#{SecureRandom.alphanumeric(4).downcase}"
      break slug unless Shelf.exists?(slug:)
    end
  end
end
