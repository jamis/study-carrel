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

class VerseGridMarkersTest < ActionDispatch::IntegrationTest
  test "verses with notes are marked in the verse grid" do
    load_isaiah
    focus = users(:one).foci.start!(title: "Holy")
    focus.notes.create!(unit: verse(11), content: "a")
    sign_in_as users(:one)

    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".cell.has", 1
    assert_select ".cell.has[aria-label=?]", "Verse 11, has a note"
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

    get focus_notes_path(@focus)
    assert_response :success
    assert_select ".nb-ref", count: 2
    assert_select ".nb-ref" do |refs|
      assert_equal [ "Isaiah 40:3", "Isaiah 40:25" ], refs.map { |r| r.text.strip }
    end
    assert_select ".nb-note", 2
    assert_select ".nb-linked a.nb-ref[href=?]", reading_path("isaiah-kjv", 40, 25)
    assert_select ".nb-note", text: /not mine/, count: 0
  end

  test "a detached note has its passage but nothing to open" do
    @focus.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                  reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "<p>set apart</p>")
    get focus_notes_path(@focus)
    assert_select ".nb-detached .nb-ref", "Morning 3"
    assert_select ".nb-detached a", 0
    assert_select ".nb-detached + .nb-note", /set apart/
  end

  test "empty state" do
    get focus_notes_path(@focus)
    assert_select ".page-empty"
  end

  test "the reading page links to it with a count" do
    @focus.notes.create!(unit: verse(3), content: "x")
    get reading_path("isaiah-kjv", 40)
    assert_select "a.menu-item[href=?]", focus_notes_path(@focus), text: "Notes on this focus (1)"
  end

  test "a past focus's notes have their page too, with the rail still on the current focus" do
    @focus.notes.create!(unit: verse(3), content: "from before")
    now = users(:one).foci.start!(title: "Now")
    get focus_notes_path(@focus.reload)
    assert_response :success
    assert_select ".nb-focus-title", "Holy"
    assert_select ".nb-lede", /· #{@focus.created_at.strftime("%b %Y")}/
    assert_select ".nb-note", /from before/
    assert_select "a.menu-item[href=?]", focus_notes_path(now)
    assert_equal now, users(:one).foci.current_one, "reading them doesn't make it current"
  end

  test "the old address goes to the current focus's notes" do
    get "/notes"
    assert_redirected_to focus_notes_path(@focus)
  end

  test "long passages are clamped with a way to expand them" do
    long = verse(3)
    long.update!(body: "word " * 100)
    @focus.notes.create!(unit: long, content: "x")
    @focus.notes.create!(unit: verse(4), content: "y")
    get focus_notes_path(@focus)
    assert_select ".nb-quote.clamped", 1
    assert_select ".nb-more", 1
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
    get export_focus_notes_path(@focus)
    assert_response :success
    assert_match "text/markdown", response.content_type
    assert_match 'filename="holy.md"', response.headers["Content-Disposition"]
    assert_includes response.body, "# Holy"
    assert_includes response.body, "hello"
  end

  test "the notes page offers copy and download" do
    get focus_notes_path(@focus)
    assert_select "[data-controller=clipboard][data-clipboard-url-value=?]", export_focus_notes_path(@focus)
    assert_select "[data-clipboard-text-value]", count: 0
    assert_select "a[href=?]", export_focus_notes_path(@focus)
  end
end
