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

  test "reloading replaces the work" do
    TextLoader.new(SAMPLE).load
    TextLoader.new(SAMPLE).load

    assert_equal 1, Work.count
    assert_equal 3, Unit.count
  end

  test "rejects text outside a unit" do
    assert_raises(TextLoader::Error) { TextLoader.new("work: X\n\nsection: 1\nstray\n").load }
  end

  test "requires a work title" do
    assert_raises(TextLoader::Error) { TextLoader.new("section: 1\n1. a\n").load }
  end
end

class BundledTextsTest < ActiveSupport::TestCase
  test "Isaiah 40 loads with 31 verses" do
    work = TextLoader.load_file(Rails.root.join("db/texts/isaiah-kjv.txt"))
    units = work.sections.find_by!(number: 40).units

    assert_equal (1..31).to_a, units.map(&:number)
    assert_match(/\AComfort ye, comfort ye my people/, units.first.body)
  end
end
