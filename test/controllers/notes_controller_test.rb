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

  test "a past focus's notes have their page too, with the rail still on the current focus" do
    @focus.notes.create!(unit: verse(3), content: "from before")
    now = users(:one).foci.start!(title: "Now")
    get focus_notes_path(@focus.reload)
    assert_response :success
    assert_select ".nb-focus-title", "Holy"
    assert_select ".rr-lede", /· #{@focus.created_at.strftime("%b %Y")}/
    assert_select ".rr-row .rr-note", /from before/
    assert_select "a.menu-item[href=?]", focus_notes_path(now)
    assert_equal now, users(:one).foci.current_one, "reading them doesn't make it current"
  end

  test "detached notes follow the run, out of it, with their kept label names and Discard" do
    @focus.notes.create!(unit: verse(3), content: "a")
    detached = @focus.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                             reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "<p>set apart</p>",
                                             label_names: [ "waiting" ])
    get focus_notes_path(@focus)
    assert_select ".rr-row[data-note-id]", 1
    assert_select ".rr-detached .rr-gone", 1 do
      assert_select ".rr-ref", "Morning 3"
      assert_select "a", 0
      assert_select ".rr-passage", "Grey field."
      assert_select ".rr-note", /set apart/
      assert_select ".rr-chip", "waiting"
      assert_select "form[action=?]", detached_note_path(detached)
    end
    assert_select ".rr-gone[data-note-id], .rr-gone[data-reread-target]", 0
  end

  test "detached notes aren't shown when rereading one label" do
    waiting = @focus.notes.create!(unit: verse(3), content: "a").label!("waiting")
    @focus.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                  reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "<p>set apart</p>")
    get focus_notes_path(@focus, label: waiting.id)
    assert_select ".rr-gone", 0
  end

  test "empty state" do
    get focus_notes_path(@focus)
    assert_select ".page-empty"
    assert_select ".page-actions", 0
  end

  test "the reading page links to it with a count" do
    @focus.notes.create!(unit: verse(3), content: "x")
    get reading_path("isaiah-kjv", 40)
    assert_select "a.menu-item[href=?]", focus_notes_path(@focus), text: "Notes on this focus (1)"
  end

  test "the old address goes to the current focus's notes" do
    get "/notes"
    assert_redirected_to focus_notes_path(@focus)
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
