require "test_helper"

class LibraryControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. a\n2. b\n\nsection: 2\n1. c\n").load
    TextLoader.new("work: Exodus\nedition: KJV\ncollection: old-testament\nposition: 2\n\nsection: 1\n1. d\n\nsection: 2\n1. e\n").load
    TextLoader.new("work: Walden\nunit: paragraph\ncollection: prose\nposition: 200\n\nsection: 1\nlabel: Economy\n1. p\n").load
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "library lists collections in order" do
    get library_path
    assert_select ".list-row-title a", text: "Sacred Texts"
    assert_select ".list-row-title a", text: "Old Testament", count: 0
    assert_select ".list-row-title a", text: "Prose"
    assert_select ".list-row:has(a[href=?]) .list-row-meta", collection_path("prose"), text: "1 work"
    # The Bible and the Book of Mormon each count as one work, however many books they hold.
    assert_select ".list-row:has(a[href=?]) .list-row-meta", collection_path("sacred-texts"), text: "2 works"
  end

  test "the library page's queries don't grow with the collection tree" do
    get library_path
    before = count_queries { get library_path }

    parent = Collection.find_by!(slug: "prose")
    3.times do |i|
      parent = Collection.create!(slug: "nested-#{i}", name: "Nested #{i}", parent:)
      Work.create!(title: "Work #{i}", slug: "work-#{i}", collection: parent)
    end
    assert_equal before, count_queries { get library_path }
    assert_select ".list-row:has(a[href=?]) .list-row-meta", collection_path("prose"), text: "4 works"
  end

  test "the Bible lists its testaments, and each testament its books" do
    get collection_path("bible")
    assert_select ".list-row-title a" do |links|
      assert_equal [ "Old Testament", "New Testament" ], links.map { |l| l.text.strip }
    end
    get collection_path("old-testament")
    assert_select ".crumbs a.crumb[href=?]", collection_path("bible"), text: "Bible"
    assert_select ".crumbs li:last-child a[aria-current=page]", "Old Testament"
  end

  test "library pages share the reading nav: breadcrumbs, history and the menu" do
    [ library_path, collection_path("old-testament"), work_path("genesis-kjv") ].each do |path|
      get path
      assert_select "header.top .crumbs a.crumb[href=?]", library_path, text: "Library"
      assert_select "header.top .history-btn"
      assert_select "header.top .menu-btn"
      assert_select "header.top .menu-item", text: "Continue reading"
      assert_select ".page-bar", 0
    end
    get work_path("genesis-kjv")
    assert_select ".crumbs li:last-child a[aria-current=page]", "Genesis"
    assert_select ".menu-panel a[href=?]", random_work_path("genesis-kjv"), text: "Random"
  end

  test "a collection lists its books in order" do
    get collection_path("old-testament")
    assert_select ".work-link-title" do |titles|
      assert_equal %w[Genesis Exodus], titles.map { |t| t.text.strip }
    end
  end

  test "Random on a parent collection reaches works in its children" do
    get random_collection_path("bible")
    assert_match %r{/read/(genesis|exodus)-kjv/}, response.location
  end

  test "reading runs on from the end of one testament into the next, but not out of the Bible" do
    TextLoader.new("work: Matthew\nedition: KJV\ncollection: new-testament\nposition: 1\n\nsection: 1\n1. x\n").load
    exodus2 = Section.joins(:work).find_by!(works: { slug: "exodus-kjv" }, number: 2)
    matthew1 = Section.joins(:work).find_by!(works: { slug: "matthew-kjv" }, number: 1)

    assert_equal matthew1, exodus2.next_section
    assert_equal exodus2, matthew1.previous_section
    assert_nil matthew1.next_section

    walden = Section.joins(:work).find_by!(works: { slug: "walden" }, number: 1)
    assert_nil walden.previous_section
  end

  test "a numbered work shows a chapter grid linking to each chapter, marking those with notes" do
    exodus = Work.find_by!(slug: "exodus-kjv")
    users(:one).foci.current_one.notes.create!(unit: exodus.sections.find_by!(number: 2).units.first, content: "x")
    get work_path("exodus-kjv")
    assert_select "nav.chapters a.tick", 2
    assert_select "nav.chapters a.tick[href=?]", reading_path("exodus-kjv", 2, 1)
    assert_select "nav.chapters a.tick.has", 1
  end

  test "a work with named sections lists them" do
    get work_path("walden")
    assert_select ".section-list a", "Economy"
  end

  test "unknown collection or work is a 404" do
    get collection_path("nope")
    assert_response :not_found
    get work_path("nope")
    assert_response :not_found
  end

  test "reading continues from the end of a chapter into the next chapter and book" do
    genesis2 = Section.joins(:work).find_by!(works: { slug: "genesis-kjv" }, number: 2)
    assert_equal [ "genesis-kjv", 1 ], [ genesis2.previous_section.work.slug, genesis2.previous_section.number ]
    assert_equal [ "exodus-kjv", 1 ], [ genesis2.next_section.work.slug, genesis2.next_section.number ]

    exodus1 = Section.joins(:work).find_by!(works: { slug: "exodus-kjv" }, number: 1)
    assert_equal genesis2, exodus1.previous_section
    assert_nil Section.joins(:work).find_by!(works: { slug: "exodus-kjv" }, number: 2).next_section
    assert_nil Section.joins(:work).find_by!(works: { slug: "genesis-kjv" }, number: 1).previous_section
  end

  test "the reader links to the neighboring chapters" do
    get reading_path("genesis-kjv", 2, 1)
    assert_select "[data-lectio-next-url-value=?]", reading_path("exodus-kjv", 1, 1)
    assert_select "[data-lectio-prev-url-value=?]", reading_path("genesis-kjv", 1, 2)
    assert_select "[data-lectio-prev-label-value=?]", "Genesis 1"
    assert_select "[data-lectio-target=prevButton]", text: "← Genesis 1"
    assert_select "[data-lectio-target=nextButton]", text: "Exodus 1 →"
    assert_select ".crumbs a.crumb[href=?]", work_path("genesis-kjv"), text: "Genesis 2"
    assert_select ".crumbs a.crumb[href=?]", library_path, text: "Library"
  end

  test "a text whose verse numbers skip ahead renders neighbors by position" do
    TextLoader.new("work: Skippy\ncollection: prose\n\nsection: 1\nlabel: One\n58. a\n60. b\n61. c\n").load
    get reading_path("skippy", 1, 58)
    assert_select "[data-lectio-target=next] b", "60"
  end

  test "units are named for the text in labels" do
    get reading_path("walden", 1, 1)
    assert_select ".tick[aria-label=?]", "Paragraph 1"
  end

  private

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
