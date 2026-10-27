class Collection < ApplicationRecord
  belongs_to :parent, class_name: "Collection", optional: true
  # Set for a user's own collection, which only they can see and which holds only their own texts (and collections);
  # nil for the bundled library. The two never mix: a user's collection is never filed under a bundled one.
  belongs_to :user, optional: true
  has_many :children, -> { order(:position, :id) }, class_name: "Collection", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :nullify
  has_many :works, -> { order(:position, :id) }, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :name, length: { maximum: 200 }, if: :user
  validates :description, length: { maximum: 300 }, if: :user
  validate :parent_is_not_self_or_descendant
  validate :parent_has_the_same_owner
  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.strip.presence }
  before_validation :set_slug, on: :create, if: :user

  scope :ordered, -> { order(:position, :id) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :bundled, -> { where(user_id: nil) }

  # Every collection a user may see: the bundled library's and their own. All lookups of a collection a request names
  # go through this, as works go through Work.visible_to.
  def self.visible_to(user) = where(user_id: [ nil, user&.id ].uniq)

  def to_param = slug

  def own? = user_id.present?

  # What its works are called where they're counted: a single work's are its books, and a user's own collection
  # holds their texts.
  def work_noun
    if single_work? then "book"
    elsif own? then "text"
    else "work"
    end
  end

  # Parent first, root first: [Scripture, Bible] for the Bible collection's trail.
  def ancestors
    chain = []
    node = parent
    while node && chain.exclude?(node)
      chain.unshift(node)
      node = node.parent
    end
    chain
  end

  # This collection's id plus the ids of everything nested under it.
  def self_and_descendant_ids
    ids = [ id ]
    frontier = [ id ]
    while frontier.any?
      frontier = Collection.where(parent_id: frontier).where.not(id: ids).pluck(:id)
      ids.concat(frontier)
    end
    ids
  end

  # Reading order runs through a collection's own works, then its child collections in order.
  def first_work = works.first || children.lazy.filter_map(&:first_work).first
  def last_work = children.reverse_order.lazy.filter_map(&:last_work).first || works.last

  # The first work after (or last work before) this collection, among its parent's other children and
  # onward up the tree. A top-level collection has no neighbors: reading stops at its edge.
  def work_after
    return unless parent

    parent.children.where("position > :p OR (position = :p AND id > :i)", p: position, i: id)
          .lazy.filter_map(&:first_work).first || parent.work_after
  end

  def work_before
    return unless parent

    parent.children.reorder(position: :desc, id: :desc).where("position < :p OR (position = :p AND id < :i)", p: position, i: id)
          .lazy.filter_map(&:last_work).first || parent.work_before
  end

  # How many works to show for this collection: its own works plus its child collections', where a child
  # that is a single work (the Bible, the Book of Mormon) counts as one however many books it holds.
  def work_count = Collection.work_counts.fetch(id)

  # Every collection's #work_count, keyed by id, from two queries, for pages that list several collections.
  def self.work_counts
    rows = pluck(:id, :parent_id, :single_work)
    own = Work.group(:collection_id).count
    children = rows.group_by { |_, parent_id, _| parent_id }
    count = ->(id) { own.fetch(id, 0) + children.fetch(id, []).sum { |child, _, single| single ? 1 : count.(child) } }
    rows.to_h { |id, *| [ id, count.(id) ] }
  end

  # Every work in this collection or any collection nested under it.
  def all_works = Work.where(collection_id: self_and_descendant_ids)

  # Deletes a user's own collection with everything in it: its texts (once their notes and keeps are set aside, see
  # DetachedNote.set_aside!) and any collections nested in it.
  def remove!
    ids = self_and_descendant_ids
    transaction do
      works = Work.where(collection_id: ids).to_a
      DetachedNote.set_aside!(Unit.joins(:section).where(sections: { work_id: works.map(&:id) }), reason: "deleted")
      works.each(&:remove!)
      Collection.where(id: ids).delete_all
    end
  end

  private

  def parent_has_the_same_owner
    errors.add(:parent, "must be another of the same owner's collections") if parent && parent.user_id != user_id
  end

  # A random suffix, as for a user's own text, so an address never gives away what another user calls a collection.
  def set_slug
    base = name.to_s.parameterize.first(60).presence || "collection"
    self.slug = loop do
      slug = "#{base}-#{SecureRandom.alphanumeric(4).downcase}"
      break slug unless Collection.exists?(slug:)
    end
  end

  def parent_is_not_self_or_descendant
    return if parent_id.nil? || new_record?

    errors.add(:parent, "can't be the collection itself or one nested in it") if self_and_descendant_ids.include?(parent_id)
  end
end
