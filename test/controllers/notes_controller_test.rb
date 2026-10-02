require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_file(Rails.root.join("db/texts/isaiah-kjv.txt"))
    @focus = Focus.start!(title: "Holy")
    @unit = Unit.find_by!(number: 25)
    sign_in_as users(:one)
  end

  test "creates a note on the current focus and appends it via turbo stream" do
    assert_difference "Note.count", 1 do
      post notes_path, params: { note: { unit_id: @unit.id, body: "Incomparable." } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal @focus, Note.last.focus
    assert_match %(action="append" target="notes_unit_#{@unit.id}"), response.body
    assert_match "Incomparable.", response.body
  end

  test "blank notes are rejected" do
    assert_no_difference "Note.count" do
      post notes_path, params: { note: { unit_id: @unit.id, body: " " } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "deletes a note via turbo stream" do
    note = @focus.notes.create!(unit: @unit, body: "x")
    assert_difference "Note.count", -1 do
      delete note_path(note), as: :turbo_stream
    end
    assert_match %(action="remove" target="#{ActionView::RecordIdentifier.dom_id(note)}"), response.body
  end

  test "cannot delete a note from another focus" do
    old = Focus.find(@focus.id)
    note = old.notes.create!(unit: @unit, body: "old")
    Focus.start!(title: "Next")
    assert_no_difference "Note.count" do
      delete note_path(note), as: :turbo_stream
    end
    assert_response :not_found
  end

  test "the reading page shows only the current focus's notes, under the right verse" do
    @focus.notes.create!(unit: @unit, body: "Old focus note")
    Focus.start!(title: "Other").notes.create!(unit: @unit, body: "Current focus note")
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "#notes_unit_#{@unit.id} .note", 1
    assert_select "#notes_unit_#{@unit.id} .note", /Current focus note/
    assert_select "#notes_unit_#{Unit.find_by!(number: 24).id} .note", 0
  end
end
