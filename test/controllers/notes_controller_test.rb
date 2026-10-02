require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = Focus.start!(title: "Holy")
    @unit = verse(25)
    sign_in_as users(:one)
  end

  test "creates a note on the current focus and appends it via turbo stream" do
    assert_difference "Note.count", 1 do
      post notes_path, params: { note: { unit_id: @unit.id, content: "Incomparable." } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal @focus, Note.last.focus
    assert_match %(action="append" target="notes_unit_#{@unit.id}"), response.body
    assert_match "Incomparable.", response.body
    assert_match %(action="replace" target="all_notes_link"), response.body
    assert_match "All notes (1)", response.body
  end

  test "blank notes are rejected" do
    assert_no_difference "Note.count" do
      post notes_path, params: { note: { unit_id: @unit.id, content: " " } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "deletes a note via turbo stream" do
    note = @focus.notes.create!(unit: @unit, content: "x")
    assert_difference "Note.count", -1 do
      delete note_path(note), as: :turbo_stream
    end
    assert_match %(action="remove" target="#{ActionView::RecordIdentifier.dom_id(note)}"), response.body
    assert_match %(action="replace" target="all_notes_link"), response.body
  end

  test "cannot delete a note from another focus" do
    old = Focus.find(@focus.id)
    note = old.notes.create!(unit: @unit, content: "old")
    Focus.start!(title: "Next")
    assert_no_difference "Note.count" do
      delete note_path(note), as: :turbo_stream
    end
    assert_response :not_found
  end

  test "the reading page shows only the current focus's notes, under the right verse" do
    @focus.notes.create!(unit: @unit, content: "Old focus note")
    Focus.start!(title: "Other").notes.create!(unit: @unit, content: "Current focus note")
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "#notes_unit_#{@unit.id} .note", 1
    assert_select "#notes_unit_#{@unit.id} .note", /Current focus note/
    assert_select "#notes_unit_#{verse(24).id} .note", 0
  end
end

class VerseStripMarkersTest < ActionDispatch::IntegrationTest
  test "verses with notes are marked on the strip" do
    load_isaiah
    focus = Focus.start!(title: "Holy")
    focus.notes.create!(unit: verse(11), content: "a")
    focus.notes.create!(unit: verse(11), content: "b")
    sign_in_as users(:one)

    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".tick.has", 1
    assert_select ".tick.has[aria-label=?]", "Verse 11, 2 notes"
  end
end

class AllNotesTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = Focus.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "lists notes in reading order, grouped by verse, linking back" do
    @focus.notes.create!(unit: verse(25), content: "late")
    @focus.notes.create!(unit: verse(3), content: "early one")
    @focus.notes.create!(unit: verse(3), content: "early two")
    old = Focus.create!(title: "Old", archived_at: 1.day.ago)
    old.notes.create!(unit: verse(1), content: "not mine")

    get notes_path
    assert_response :success
    assert_select ".fv-ref", count: 2
    assert_select ".fv-ref" do |refs|
      assert_equal [ "Isaiah 40:3", "Isaiah 40:25" ], refs.map { |r| r.text.strip }
    end
    assert_select ".fv-item:first-of-type .fv-note", 2
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
    assert_select "a.chip[href=?]", notes_path, text: "All notes (1)"
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
    @focus = Focus.start!(title: "Holy")
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
