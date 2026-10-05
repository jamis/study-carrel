# A place to roll a random passage in: one work, a collection with everything nested under it, or the whole
# library (place nil). Rolls are balanced: each branch of the library gets an even chance at every level (Sacred
# Texts > Bible, Book of Mormon, Quran, ... alike), then the roll picks evenly among the units of the work it reaches;
# a single-work collection (the Bible) counts as one branch and is even by unit inside, so Obadiah is no likelier than
# Psalm 119's verses.
class RandomScope
  attr_reader :place

  def initialize(place) = @place = place

  def self.library = new(nil)

  # The places enclosing a work or collection, innermost first: itself, its collections out to the top, the library.
  def self.chain_for(place)
    collection = place.is_a?(Work) ? place.collection : place
    collections = collection ? [ *collection.ancestors, collection ].reverse : []
    places = place.is_a?(Work) ? [ place, *collections ] : collections
    [ *places, nil ].map { new(it) }
  end

  # The reader's default: the innermost collection, or the work itself when it sits in none.
  def self.default_for(work) = new(work.collection || work)

  def label
    case place
    when nil then "Whole library"
    when Work then place.title
    else place.name
    end
  end

  # For the menu: "Random in Job", "Random anywhere in the library".
  def in_words = place ? "in #{label}" : "anywhere in the library"

  def ==(other) = other.is_a?(RandomScope) && other.place == place
  alias eql? ==
  def hash = place.hash

  # A random unit, or nil when the scope holds none.
  def unit
    work_id = weighted_work(work_ids_under(balanced_leaf)) or return
    # A random offset, not ORDER BY RANDOM(): SQLite returns the same row for the latter when the scope is a subquery.
    Unit.joins(:section).where(sections: { work_id: }).order(:id).offset(rand(counts[work_id])).includes(section: :work).first
  end

  private

  # Step down from the scope, choosing evenly among the non-empty branches at each level, until reaching a work or a
  # single-work collection.
  def balanced_leaf
    node = place
    until node.is_a?(Work) || (node.is_a?(Collection) && node.single_work?)
      options = branches(node).select { |b| work_ids_under(b).any? }
      return node if options.empty?

      node = options.sample
    end
    node
  end

  def weighted_work(ids)
    return if ids.empty?

    roll = rand(ids.sum { counts[it] })
    ids.find { |id| (roll -= counts[id]) < 0 }
  end

  def branches(collection)
    id = collection&.id
    collections.select { it.parent_id == id } + works.select { it.collection_id == id }
  end

  # Ids of the works with any units under a node; nil is the whole library.
  def work_ids_under(node)
    case node
    when nil then works.map(&:id)
    when Work then counts.key?(node.id) ? [ node.id ] : []
    else branches(node).flat_map { work_ids_under(it) }
    end
  end

  # Units per work, for the works that have any.
  def counts = @counts ||= Unit.joins(:section).group("sections.work_id").count
  def works = @works ||= Work.where(id: counts.keys).ordered.select(:id, :collection_id).to_a
  def collections = @collections ||= Collection.ordered.to_a
end
