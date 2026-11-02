require "test_helper"

class LibrarySearchTest < ActiveSupport::TestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new(<<~TEXT).load
      work: Genesis
      edition: KJV
      collection: old-testament
      position: 1

      section: 1
      1. In the beginning God created the heaven and the earth.
      2. And God blessed the seventh day, and sanctified it.

      section: 2
      1. Be ye holy, for the LORD's house is holy.
    TEXT
    TextLoader.new("work: Matthew\nedition: KJV\ncollection: new-testament\nposition: 1\n\nsection: 1\n1. Hallowed be thy name, holy one.\n").load
    TextLoader.new("work: Walden\nunit: paragraph\ncollection: prose\nposition: 1\n\nsection: 1\nlabel: Economy\n1. I went to the woods; holiness and the café.\n").load
    @genesis = Work.find_by!(slug: "genesis-kjv")
  end

  def refs(query, place: nil) = LibrarySearch.new(query, place:).page(1).map(&:reference)

  test "every word must appear, and words are stemmed" do
    assert_equal [ "Genesis 2:1", "Matthew 1:1" ], refs("holy be")
    assert_includes refs("holy"), "Walden: Economy, paragraph 1", "holiness and holy share a stem"
  end

  test "quotes make a phrase and a trailing * matches a word's beginning" do
    assert_equal [ "Genesis 1:1" ], refs(%("the heaven and"))
    assert_empty refs(%("heaven the"))
    assert_equal [ "Genesis 1:2" ], refs("sanctif*")
  end

  test "FTS syntax and punctuation are taken as plain text" do
    assert_equal [ "Genesis 2:1" ], refs("LORD's")
    assert_empty refs("holy NOT house"), "NOT is a word to find, not an operator"
    assert_equal [ "Walden: Economy, paragraph 1" ], refs("cafe")
    assert_not LibrarySearch.new(%(* "" -)).searching?
    assert_empty LibrarySearch.new("").page(1)
  end

  test "results come in library order with a count per work" do
    search = LibrarySearch.new("holy")
    # Poetry and Prose come before Sacred Texts in the library, whatever the works' own positions say.
    assert_equal [ "Walden", "Genesis", "Matthew" ], search.counts.keys.map(&:title)
    assert_equal [ 1, 1, 1 ], search.counts.values
    assert_equal 3, search.total
  end

  test "a search stays inside its work or collection" do
    assert_equal [ "Genesis 2:1" ], refs("holy", place: @genesis)
    assert_equal [ "Genesis 2:1", "Matthew 1:1" ], refs("holy", place: Collection.find_by!(slug: "bible"))
    assert_empty refs("holy", place: Collection.find_by!(slug: "poetry"))
  end

  test "excerpts mark the matches" do
    excerpt = LibrarySearch.new("holy", place: @genesis).page(1).first.excerpt
    assert_equal "Be ye \u0002holy\u0003, for the LORD's house is \u0002holy\u0003.", excerpt
  end

  test "pages hold PER_PAGE results" do
    TextLoader.new("work: Many\n\nsection: 1\n#{(1..55).map { "#{it}. amen" }.join("\n")}\n").load
    search = LibrarySearch.new("amen")
    assert_equal 2, search.pages
    assert_equal [ 51, 55 ], search.page(2).map(&:number).values_at(0, -1)
  end

  test "reloading a text refreshes the index" do
    TextLoader.new("work: Matthew\nedition: KJV\ncollection: new-testament\nposition: 1\n\nsection: 1\n1. Our Father which art in heaven.\n").load
    assert_equal [ "Genesis 2:1" ], refs("holy", place: Collection.find_by!(slug: "bible"))
    assert_equal [ "Matthew 1:1" ], refs("father")

    Unit.reindex_search
    assert_equal [ "Matthew 1:1" ], refs("father")
  end

  test "around a section: the results before it, those in it, and the nearest either side" do
    around = LibrarySearch.new("holy").around(@genesis.sections.second)
    assert_equal [ 3, 1 ], [ around.total, around.before ]
    assert_equal [ "Genesis 2:1" ], around.hits.map(&:reference)
    assert_equal [ "Walden: Economy, paragraph 1", "Matthew 1:1" ], [ around.previous, around.next ].map(&:reference)

    around = LibrarySearch.new("holy").around(@genesis.sections.first)
    assert_equal [ 1, [], "Genesis 2:1" ], [ around.before, around.hits, around.next.reference ]
    assert_equal "Walden: Economy, paragraph 1", around.previous.reference
  end

  test "around a section in reading order, in the place searched or out of it" do
    TextLoader.new("work: Many\n\nsection: 1\n1. amen\n2. so\n3. amen\n\nsection: 2\n1. so\n\nsection: 3\n1. amen\n").load
    many = Work.find_by!(slug: "many")
    around = LibrarySearch.new("amen", place: many).around(many.sections.first)
    assert_equal [ 3, 0, [ 1, 3 ], nil, "Many 3:1" ], [ around.total, around.before, around.hits.map(&:number), around.previous, around.next.reference ]
    around = LibrarySearch.new("amen", place: many).around(many.sections.second)
    assert_equal [ 2, [], "Many 1:3", "Many 3:1" ], [ around.before, around.hits, around.previous.reference, around.next.reference ]

    around = LibrarySearch.new("holy", place: @genesis).around(Work.find_by!(slug: "matthew-kjv").sections.first)
    assert_equal [ 1, 1, [], "Genesis 2:1", nil ], [ around.total, around.before, around.hits, around.previous.reference, around.next ]
  end

  test "a shelf searches the works on it and under its collections" do
    shelf = users(:one).shelves.create!(name: "Mine")
    shelf.replace!([ Collection.find_by!(slug: "old-testament"), Work.find_by!(slug: "walden") ])
    assert_equal [ "Walden: Economy, paragraph 1", "Genesis 2:1" ], refs("holy", place: shelf), "in library order"
  end
end
