class Collection < ApplicationRecord
  belongs_to :parent, class_name: "Collection", optional: true
  has_many :children, -> { order(:position, :id) }, class_name: "Collection", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :nullify
  has_many :works, -> { order(:position, :id) }, dependent: :nullify

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validate :parent_is_not_self_or_descendant

  scope :ordered, -> { order(:position, :id) }
  scope :top_level, -> { where(parent_id: nil) }

  def to_param = slug

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
  def work_count = works.size + children.sum { |c| c.single_work? ? 1 : c.work_count }

  # Every work in this collection or any collection nested under it.
  def all_works = Work.where(collection_id: self_and_descendant_ids)

  private

  def parent_is_not_self_or_descendant
    return if parent_id.nil? || new_record?

    errors.add(:parent, "can't be the collection itself or one nested in it") if self_and_descendant_ids.include?(parent_id)
  end
end
