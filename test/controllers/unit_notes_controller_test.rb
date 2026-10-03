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
    assert_match "All notes (1)", response.body
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
end
