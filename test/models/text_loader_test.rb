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
    assert_equal "Sample: Two", work.sections.last.name
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

  test "collections.yml can nest collections, in any order" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "collections.yml")
      File.write(path, <<~YAML)
        - slug: ot
          name: Old Testament
          parent: bible
        - slug: bible
          name: Bible
      YAML
      TextLoader.load_collections(path)
    end
    assert_equal "Bible", Collection.find_by!(slug: "ot").parent.name
    assert_nil Collection.find_by!(slug: "bible").parent
  end

  test "rejects an unknown collection" do
    assert_raises(TextLoader::Error) { TextLoader.new(SAMPLE.sub("edition: KJV\n", "edition: KJV\ncollection: nope\n")).load }
  end

  test "poetry keeps line breaks inside a unit and names its units" do
    poem = <<~TXT
      work: Emily Dickinson
      unit: stanza
      lines: keep

      section: 1
      label: Success
      1. Success is counted sweetest
      By those who ne'er succeed.
      2. Not one of all the purple host
    TXT
    work = TextLoader.new(poem).load
    section = work.sections.first

    assert_equal "stanza", work.unit_name
    assert_equal "Success is counted sweetest\nBy those who ne'er succeed.", section.units.first.body
    assert_equal "Emily Dickinson: Success, stanza 2", section.units.last.reference
  end

  test "references: numbered chapters read Book C:V, named sections read Work: Label, unit N" do
    work = TextLoader.new(SAMPLE).load
    assert_equal "Sample 1:2", work.sections.first.units.last.reference

    named = TextLoader.new(SAMPLE.sub("work: Sample", "work: Walden\nunit: paragraph")).load.sections.last
    assert_equal "Walden: Two", named.name
    assert_equal "Walden: Two, paragraph 1", named.units.first.reference
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

  test "the whole bundled library loads: the Bible, Dickinson's poems and Walden" do
    TextLoader.load_all
    ot = Collection.find_by!(slug: "old-testament")
    ot_sections = Section.joins(:work).where(works: { collection_id: ot.id })

    assert_equal 39, ot.works.count
    assert_equal %w[Genesis Exodus], ot.works.first(2).map(&:title)
    assert_equal 929, ot_sections.count
    assert_equal 23_145, Unit.where(section: ot_sections).count
    assert_equal 176, ot_sections.find_by!(works: { slug: "psalms-kjv" }, number: 119).units.count

    assert_equal %w[Bible Old\ Testament New\ Testament LDS\ Scripture Book\ of\ Mormon World\ Scripture Poetry Emily\ Dickinson Robert\ Frost Edgar\ Allan\ Poe Prose], Collection.reorder(:id).map(&:name)
    assert_equal %w[Bible LDS\ Scripture World\ Scripture Poetry Prose], Collection.top_level.ordered.map(&:name)

    nt = Collection.find_by!(slug: "new-testament")
    nt_sections = Section.joins(:work).where(works: { collection_id: nt.id })
    assert_equal 27, nt.works.count
    assert_equal %w[Matthew Mark], nt.works.first(2).map(&:title)
    assert_equal "Revelation", nt.works.last.title
    assert_equal 260, nt_sections.count
    assert_equal 7_957, Unit.where(section: nt_sections).count
    assert_equal "Malachi", nt.works.first.previous_work.title
    assert_nil nt.works.last.next_work

    bom = Collection.find_by!(slug: "book-of-mormon")
    bom_sections = Section.joins(:work).where(works: { collection_id: bom.id })
    assert_equal "LDS Scripture", bom.parent.name
    assert_equal 15, bom.works.count
    assert_equal %w[1\ Nephi 2\ Nephi], bom.works.first(2).map(&:title)
    assert_equal 239, bom_sections.count
    assert_equal 6_604, Unit.where(section: bom_sections).count
    assert_equal "Public-domain text", bom.works.first.edition

    frost = Collection.find_by!(slug: "robert-frost")
    assert_equal "Poetry", frost.parent.name
    assert_equal [ "The Pasture", "A Boy’s Will", "North of Boston", "Mountain Interval", "New Hampshire", "West-Running Brook" ], frost.works.map(&:title)
    assert_equal 163, Section.joins(:work).where(works: { collection_id: frost.id }).count
    stopping = Section.joins(:work).find_by!(works: { slug: "frost-new-hampshire" }, label: "Stopping by Woods on a Snowy Evening")
    assert_equal 4, stopping.units.count
    assert_equal "Whose woods these are I think I know.\nHis house is in the village though;\nHe will not see me stopping here\nTo watch his woods fill up with snow.", stopping.units.first.body

    poe = Collection.find_by!(slug: "edgar-allan-poe")
    assert_equal [ "Poems", "Poems Written in Youth", "Tamerlane", "Al Aaraaf" ], poe.works.map(&:title)
    raven = Section.joins(:work).find_by!(works: { slug: "poe-poems" }, label: "The Raven")
    assert_equal 18, raven.units.count
    assert_equal "Emily Dickinson", Work.find_by!(slug: "dickinson").collection.name

    world = Collection.find_by!(slug: "world-scripture")
    assert_equal %w[Dhammapada Tao\ Te\ Ching Bhagavad\ Gita\ (The\ Song\ Celestial) Quran], world.works.map(&:title)
    counts = ->(slug) { Section.joins(:work).where(works: { slug: slug }).then { |s| [ s.count, Unit.where(section: s).count ] } }
    assert_equal [ 26, 414 ], counts.("dhammapada")
    assert_equal [ 81, 253 ], counts.("tao-te-ching")
    assert_equal [ 18, 240 ], counts.("bhagavad-gita")
    assert_equal [ 114, 6_245 ], counts.("quran")
    assert_equal [ 12, 418 ], counts.("meditations")
    assert_equal "Prose", Work.find_by!(slug: "meditations").collection.name

    # The Quran is in the traditional order, not Rodwell's chronological one.
    cow = Section.joins(:work).find_by!(works: { slug: "quran" }, number: 2)
    assert_equal "2. The Cow", cow.label
    assert_equal "Al-Fatihah", Section.joins(:work).find_by!(works: { slug: "quran" }, number: 1).label.delete_prefix("1. ")
    assert_equal 4, Section.joins(:work).find_by!(works: { slug: "quran" }, number: 112).units.count
    assert_no_match(/\d/, Section.joins(:work).find_by!(works: { slug: "quran" }, number: 96).units.map(&:body).join)

    # Müller prints verses 58 and 59 as one passage.
    dhp = Work.find_by!(slug: "dhammapada").sections
    assert_equal (21..32).to_a, dhp.find_by!(number: 2).units.map(&:number)
    assert_includes dhp.find_by!(label: "The Fool").units.map(&:number), 60
    assert_not_includes Unit.where(section: dhp).map(&:number), 59
    assert_equal 18, Work.find_by!(slug: "walden").sections.count
    assert_equal "Walden: Economy", Work.find_by!(slug: "walden").sections.first.name
    success = Work.find_by!(slug: "dickinson").sections.find_by!(label: "Success")
    assert_equal "Emily Dickinson: Success, stanza 1", success.units.first.reference
    assert_includes success.units.first.body, "\n"
  end
end
