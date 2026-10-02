require "test_helper"

class TextLoaderTest < ActiveSupport::TestCase
  SAMPLE = <<~TXT
    work: Sample
    edition: KJV

    section: 1
    1. First line
    wrapped here.
    2. Second line

    section: 2
    label: Two
    1. Another
  TXT

  test "loads works, sections and units" do
    work = TextLoader.new(SAMPLE).load

    assert_equal "sample-kjv", work.slug
    assert_equal "Sample KJV", work.name
    assert_equal [ 1, 2 ], work.sections.map(&:number)
    assert_equal [ "First line wrapped here.", "Second line" ], work.sections.first.units.map(&:body)
    assert_equal "Sample Two", work.sections.last.name
  end

  test "reloading updates in place and keeps notes" do
    work = TextLoader.new(SAMPLE).load
    unit = work.sections.first.units.first
    note = Focus.start!(title: "F").notes.create!(unit: unit, content: "<p>keep me</p>")

    changed = SAMPLE.sub("First line", "First line, revised")
    TextLoader.new(changed).load

    assert_equal 1, Work.count
    assert_equal 3, Unit.count
    assert_equal "First line, revised wrapped here.", unit.reload.body
    assert Note.exists?(note.id)
  end

  test "places the work in a collection with a position" do
    Collection.create!(slug: "ot", name: "Old Testament", position: 1)
    work = TextLoader.new(SAMPLE.sub("edition: KJV\n", "edition: KJV\ncollection: ot\nposition: 7\n")).load

    assert_equal "Old Testament", work.collection.name
    assert_equal 7, work.position
  end

  test "rejects an unknown collection" do
    assert_raises(TextLoader::Error) { TextLoader.new(SAMPLE.sub("edition: KJV\n", "edition: KJV\ncollection: nope\n")).load }
  end

  test "rejects text outside a unit" do
    assert_raises(TextLoader::Error) { TextLoader.new("work: X\n\nsection: 1\nstray\n").load }
  end

  test "requires a work title" do
    assert_raises(TextLoader::Error) { TextLoader.new("section: 1\n1. a\n").load }
  end
end

class BundledTextsTest < ActiveSupport::TestCase
  test "Isaiah 40 loads with 31 verses, in the Old Testament" do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    work = TextLoader.load_file(Rails.root.join("db/texts/isaiah-kjv.txt"))
    assert_equal "Old Testament", work.collection.name
    units = work.sections.find_by!(number: 40).units

    assert_equal (1..31).to_a, units.map(&:number)
    assert_match(/\AComfort ye, comfort ye my people/, units.first.body)
  end

  test "the whole bundled library loads: 39 Old Testament books, 929 chapters, 23,145 verses" do
    TextLoader.load_all

    assert_equal 39, Work.where(collection: Collection.find_by!(slug: "old-testament")).count
    assert_equal %w[Genesis Exodus], Work.ordered.first(2).map(&:title)
    assert_equal 929, Section.count
    assert_equal 23_145, Unit.count
    assert_equal 176, Section.joins(:work).find_by!(works: { slug: "psalms-kjv" }, number: 119).units.count
  end
end
