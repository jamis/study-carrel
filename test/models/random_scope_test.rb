require "test_helper"

class RandomScopeTest < ActiveSupport::TestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    verses = (1..9).map { "#{it}. v#{it}" }.join("\n")
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n#{verses}\n").load
    TextLoader.new("work: Obadiah\nedition: KJV\ncollection: old-testament\nposition: 31\n\nsection: 1\n1. o\n").load
    TextLoader.new("work: Dhammapada\ncollection: sacred-texts\nposition: 10\n\nsection: 1\n1. d\n").load
    @genesis = Work.find_by!(slug: "genesis-kjv")
  end

  def slugs(scope, times = 200) = times.times.map { scope.unit.section.work.slug }.tally

  test "each branch gets an even chance, and a single-work collection is even by unit inside" do
    seen = slugs(RandomScope.new(Collection.find_by!(slug: "sacred-texts")))
    assert_operator seen["dhammapada"], :>, 60, "the Dhammapada should get about half: #{seen}"
    assert_operator seen.fetch("obadiah-kjv", 0), :<, 40, "Obadiah is one verse of ten in the Bible: #{seen}"
  end

  test "a scope with no units yields nothing" do
    assert_nil RandomScope.new(Collection.find_by!(slug: "poetry")).unit
  end

  test "the chain runs from the work out to the library, and the default is the innermost collection" do
    chain = RandomScope.chain_for(@genesis)
    assert_equal [ "Genesis", "Old Testament", "Bible", "Sacred Texts", "Whole library" ], chain.map(&:label)
    assert_equal RandomScope.new(Collection.find_by!(slug: "old-testament")), RandomScope.default_for(@genesis)

    dhammapada = Work.find_by!(slug: "dhammapada")
    assert_equal [ "Dhammapada", "Sacred Texts", "Whole library" ], RandomScope.chain_for(dhammapada).map(&:label)
    assert_equal [ "Bible", "Sacred Texts", "Whole library" ], RandomScope.chain_for(Collection.find_by!(slug: "bible")).map(&:label)
  end

  test "a work outside any collection is its own default" do
    TextLoader.new("work: Loose\n\nsection: 1\n1. l\n").load
    loose = Work.find_by!(slug: "loose")
    assert_equal RandomScope.new(loose), RandomScope.default_for(loose)
  end
end
