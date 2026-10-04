require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @unit = verse(25)
    sign_in_as users(:one)
  end

  test "the reading page edits only the current focus's note for the verse" do
    @focus.notes.create!(unit: @unit, content: "Old focus note")
    users(:one).foci.start!(title: "Other").notes.create!(unit: @unit, content: "Current focus note")
    get reading_path("isaiah-kjv", 40, 25)
    assert_match "Current focus note", css_select("turbo-frame#note_editor").to_s
    assert_no_match "Old focus note", css_select("turbo-frame#note_editor").to_s
  end

  test "a verse has at most one note per focus" do
    @focus.notes.create!(unit: @unit, content: "a")
    assert_not @focus.notes.build(unit: @unit, content: "b").valid?
    assert users(:one).foci.start!(title: "Next").notes.build(unit: @unit, content: "b").valid?
  end
end

class VerseStripMarkersTest < ActionDispatch::IntegrationTest
  test "verses with notes are marked on the strip" do
    load_isaiah
    focus = users(:one).foci.start!(title: "Holy")
    focus.notes.create!(unit: verse(11), content: "a")
    sign_in_as users(:one)

    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".tick.has", 1
    assert_select ".tick.has[aria-label=?]", "Verse 11, has a note"
  end
end

class AllNotesTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "lists notes in reading order, linking back" do
    @focus.notes.create!(unit: verse(25), content: "late")
    @focus.notes.create!(unit: verse(3), content: "early")
    old = users(:one).foci.create!(title: "Old", archived_at: 1.day.ago)
    old.notes.create!(unit: verse(1), content: "not mine")

    get notes_path
    assert_response :success
    assert_select ".fv-ref", count: 2
    assert_select ".fv-ref" do |refs|
      assert_equal [ "Isaiah 40:3", "Isaiah 40:25" ], refs.map { |r| r.text.strip }
    end
    assert_select ".fv-item:first-of-type .fv-note", 1
    assert_select ".fv-ref[href=?]", reading_path("isaiah-kjv", 40, 25)
    assert_select ".fv-note", text: /not mine/, count: 0
  end

  test "empty state" do
    get notes_path
    assert_select ".page-empty"
  end

  test "the reading page links to it with a count" do
    @focus.notes.create!(unit: verse(3), content: "x")
    get reading_path("isaiah-kjv", 40)
    assert_select "a.menu-item[href=?]", notes_path, text: "All notes (1)"
  end

  test "long passages are clamped with a way to expand them" do
    long = verse(3)
    long.update!(body: "word " * 100)
    @focus.notes.create!(unit: long, content: "x")
    @focus.notes.create!(unit: verse(4), content: "y")
    get notes_path
    assert_select ".fv-quote.clamped", 1
    assert_select ".fv-more", 1
  end
end

class ExportTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @focus.notes.create!(unit: verse(3), content: "<p>hello</p>")
    sign_in_as users(:one)
  end

  test "downloads the Markdown" do
    get export_notes_path
    assert_response :success
    assert_match "text/markdown", response.content_type
    assert_match 'filename="holy.md"', response.headers["Content-Disposition"]
    assert_includes response.body, "# Holy"
    assert_includes response.body, "hello"
  end

  test "all-notes page offers copy and download" do
    get notes_path
    assert_select "[data-controller=clipboard][data-clipboard-text-value*=?]", "# Holy"
    assert_select "a[href=?]", export_notes_path
  end
end
