require "test_helper"

class FreeNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @focus.notes.create!(unit: verse(3), content: "On a passage")
    sign_in_as users(:one)
  end

  test "a new note's editor posts, and its first save makes the note and says where to save next" do
    get new_focus_note_path(@focus), headers: { "Turbo-Frame" => "note_editor" }
    assert_select "turbo-frame#note_editor form[action=?][method=post]", focus_notes_path(@focus)

    assert_difference -> { @focus.notes.free.count }, 1 do
      post focus_notes_path(@focus), params: { note: { content: "<p>Holiness keeps stooping.</p>" } }, as: :turbo_stream
    end
    note = @focus.free_notes.sole
    assert_equal "true", response.headers["X-Noted"]
    assert_equal note.id.to_s, response.headers["X-Note-Id"]
    assert_equal focus_note_path(@focus, note), response.headers["X-Save-Url"]
    assert_equal "PUT", response.headers["X-Save-Method"]
    assert_match %(target="new_note_labels"), response.body
  end

  test "an empty first save makes nothing" do
    assert_no_difference -> { Note.count } do
      post focus_notes_path(@focus), params: { note: { content: "" } }, as: :turbo_stream
    end
    assert_response :no_content
  end

  test "saving changes it; clearing it deletes it, and the editor starts again from a new one" do
    note = @focus.notes.create!(content: "Before")
    get focus_note_path(@focus, note), headers: { "Turbo-Frame" => "note_editor" }
    assert_select "turbo-frame#note_editor form[action=?]", focus_note_path(@focus, note)

    put focus_note_path(@focus, note), params: { note: { content: "<p>After</p>" } }, as: :turbo_stream
    assert_equal "After", note.reload.content.to_plain_text
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(note, :reread_text)}"), response.body

    put focus_note_path(@focus, note), params: { note: { content: "" } }, as: :turbo_stream
    assert_not Note.exists?(note.id)
    assert_equal "false", response.headers["X-Noted"]
    assert_equal focus_notes_path(@focus), response.headers["X-Save-Url"]
    assert_equal "POST", response.headers["X-Save-Method"]
  end

  test "made a note of from the scratchpad, it joins the reread's notes on the whole" do
    post focus_notes_path(@focus), params: { lift: true, note: { content: "<p>Compare Amos 5?</p>" } }, as: :turbo_stream
    note = @focus.free_notes.sole
    assert_match %(action="append" target="reread_free"), response.body
    assert_match ActionView::RecordIdentifier.dom_id(note, :reread), response.body
  end

  test "a past focus's notes on the whole can be written and changed too" do
    users(:one).foci.start!(title: "Rest")
    post focus_notes_path(@focus), params: { note: { content: "<p>Later</p>" } }, as: :turbo_stream
    assert_equal "Later", @focus.free_notes.sole.content.to_plain_text
  end

  test "only notes on the whole are edited this way; a passage's note is the reader's" do
    passage_note = @focus.notes.find_by!(unit: verse(3))
    put focus_note_path(@focus, passage_note), params: { note: { content: "<p>Hijacked</p>" } }, as: :turbo_stream
    assert_response :not_found
    get focus_note_path(@focus, passage_note)
    assert_response :not_found
  end

  test "the reread lists them after the notes on passages; the notes page and export show them" do
    @focus.notes.create!(content: "Across them all")
    get focus_reread_path(@focus)
    assert_select "#reread_free .rr-free-head", "On the whole focus"
    assert_select "#reread_free .rr-row .rr-ref", /\AWritten /
    assert_select "#reread_free .rr-row .rr-note", /Across them all/
    assert_select ".rr-new", "+ New note"
    assert_select ".rr-pad-head button", /New note/

    get focus_notes_path(@focus)
    assert_select ".nb-lede", /1 note, in reading order, and 1 on the whole/
    assert_select ".nb-detached-head", "On the whole focus"
    assert_select ".nb-note", /Across them all/
  end

  test "another reader's focus can't be written in" do
    sign_out
    sign_in_as users(:two)
    post focus_notes_path(@focus), params: { note: { content: "<p>Hijacked</p>" } }, as: :turbo_stream
    assert_response :not_found
    get new_focus_note_path(@focus)
    assert_response :not_found
    assert_empty @focus.free_notes
  end
end
