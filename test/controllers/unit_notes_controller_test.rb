require "test_helper"

class UnitNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @unit = verse(25)
    sign_in_as users(:one)
  end

  test "the first save creates the note" do
    assert_difference "Note.count", 1 do
      put unit_note_path(@unit), params: { note: { content: "Incomparable." } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal "true", response.headers["X-Noted"]
    assert_equal [ @focus, @unit ], [ Note.last.focus, Note.last.unit ]
    assert_match "Notes on this focus (1)", response.body
  end

  test "a save from an editor opened under another focus is refused" do
    users(:one).foci.start!(title: "Newer")
    assert_no_difference "Note.count" do
      put unit_note_path(@unit), params: { focus_id: @focus.id, note: { content: "Meant for Holy." } }, as: :turbo_stream
    end
    assert_response :conflict
  end

  test "a save with no current focus is refused, not redirected" do
    @focus.archive!
    assert_no_difference "Note.count" do
      put unit_note_path(@unit), params: { focus_id: @focus.id, note: { content: "Too late." } }, as: :turbo_stream
    end
    assert_response :conflict
  end

  test "a save that names the current focus goes through" do
    put unit_note_path(@unit), params: { focus_id: @focus.id, note: { content: "Incomparable." } }, as: :turbo_stream
    assert_response :success
    assert_equal @focus, Note.last.focus
  end

  test "note text is kept out of the logs" do
    put unit_note_path(@unit), params: { note: { content: "Private thought." } }, as: :turbo_stream
    assert_equal "[FILTERED]", request.filtered_parameters.dig("note", "content")
  end

  test "later saves update the same note" do
    put unit_note_path(@unit), params: { note: { content: "one" } }, as: :turbo_stream
    assert_no_difference "Note.count" do
      put unit_note_path(@unit), params: { note: { content: "two" } }, as: :turbo_stream
    end
    assert_equal "two", Note.last.content.to_plain_text
  end

  test "clearing the editor deletes the note" do
    @focus.notes.create!(unit: @unit, content: "x")
    assert_difference "Note.count", -1 do
      put unit_note_path(@unit), params: { note: { content: "" } }, as: :turbo_stream
    end
    assert_equal "false", response.headers["X-Noted"]
  end

  test "saving nothing on a verse with no note does nothing" do
    assert_no_difference "Note.count" do
      put unit_note_path(@unit), params: { note: { content: " " } }, as: :turbo_stream
    end
    assert_response :success
  end

  test "the editor frame shows this focus's note" do
    @focus.notes.create!(unit: @unit, content: "Mine")
    get unit_note_path(@unit), headers: { "Turbo-Frame" => "note_editor" }
    assert_response :success
    assert_select "turbo-frame#note_editor form[action=?]", unit_note_path(@unit)
    assert_match "Mine", response.body
  end

  test "another user's note on the same verse is neither shown nor changed" do
    other = users(:two).foci.start!(title: "Theirs")
    theirs = other.notes.create!(unit: @unit, content: "Private")
    get unit_note_path(@unit)
    assert_no_match "Private", response.body
    put unit_note_path(@unit), params: { note: { content: "Mine" } }, as: :turbo_stream
    assert_equal "Private", theirs.reload.content.to_plain_text
  end

  # ---------- under another focus, written from the reader ----------

  test "a passage's note can be saved under a past focus without making it current" do
    past = users(:one).foci.start!(title: "Comfort")
    @focus = users(:one).foci.start!(title: "Holy, again")
    @focus.update!(last_unit: verse(3))
    assert_difference -> { past.notes.count }, 1 do
      put focus_unit_note_path(past, @unit), params: { focus_id: past.id, note: { content: "Even the question comforts." } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal "true", response.headers["X-Noted"]
    assert_equal @unit, past.notes.last.unit
    assert_equal @focus, users(:one).foci.current_one
    assert_equal verse(3), @focus.reload.last_unit
    # Nothing of the current focus's on the page changes.
    assert_no_match "focus_notes_link", response.body
    assert_no_match "focus_sheet_all", response.body
  end

  test "clearing a note under a past focus deletes it" do
    past = @focus
    users(:one).foci.start!(title: "Newer")
    past.notes.create!(unit: @unit, content: "x")
    assert_difference -> { past.notes.count }, -1 do
      put focus_unit_note_path(past, @unit), params: { note: { content: "" } }, as: :turbo_stream
    end
    assert_equal "false", response.headers["X-Noted"]
  end

  test "under a past focus, the editor is headed by it with the way back, and saves to it" do
    past = @focus
    users(:one).foci.start!(title: "Newer")
    past.notes.create!(unit: @unit, content: "Under Holy")
    get focus_unit_note_path(past, @unit), headers: { "Turbo-Frame" => "note_editor" }
    assert_response :success
    assert_select "turbo-frame#note_editor .note-under-title", "Holy"
    assert_select "turbo-frame#note_editor a.note-under-back[href=?]", unit_note_path(@unit), text: /Back to Newer/
    assert_select "turbo-frame#note_editor form[action=?]", focus_unit_note_path(past, @unit)
    assert_match "Under Holy", response.body
    assert_select ".note-also", false
  end

  test "under the current focus, the editor names the past focuses with a note on the passage" do
    past = @focus
    past.notes.create!(unit: @unit, content: "x")
    users(:one).foci.start!(title: "Bare").notes.create!(unit: verse(3), content: "y")
    users(:one).foci.start!(title: "Newer")
    get unit_note_path(@unit), headers: { "Turbo-Frame" => "note_editor" }
    assert_select ".note-under", false
    assert_select ".note-also a.note-also-focus[href=?]", focus_unit_note_path(past, @unit), text: "Holy"
    assert_select ".note-also a", count: 1
  end

  test "another user's focus is a 404" do
    theirs = users(:two).foci.start!(title: "Theirs")
    get focus_unit_note_path(theirs, @unit)
    assert_response :not_found
    assert_no_difference "Note.count" do
      put focus_unit_note_path(theirs, @unit), params: { note: { content: "Mine" } }, as: :turbo_stream
    end
    assert_response :not_found
  end
end
