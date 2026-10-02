require "test_helper"

# Readers share the library but nothing else: one user's foci, notes and position are invisible
# (and untouchable) to another, admins included.
class IsolationTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @owner, @other = users(:one), users(:two)
    @owner_focus = @owner.foci.start!(title: "Owner's focus")
    @owner_note = @owner_focus.notes.create!(unit: verse(3), content: "Owner's private thought")
    @owner.update!(admin: true)
  end

  test "a new reader starts with no focus, not the owner's" do
    sign_in_as @other
    get root_path
    assert_redirected_to new_focus_path
    get reading_path("isaiah-kjv", 40, 3)
    assert_redirected_to new_focus_path
  end

  test "each reader has their own current focus; starting one doesn't archive the other's" do
    sign_in_as @other
    post foci_path, params: { focus: { title: "Other's focus" } }
    assert_nil @owner_focus.reload.archived_at
    assert_equal "Other's focus", @other.foci.current_one.title
    assert_equal "Owner's focus", @owner.foci.current_one.title
  end

  test "notes, exports and the foci list show only the reader's own" do
    @other.foci.start!(title: "Other's focus")
    sign_in_as @other

    get notes_path
    assert_no_match "Owner's private thought", response.body
    get export_notes_path
    assert_no_match "Owner's private thought", response.body
    assert_no_match "Owner's focus", response.body
    get foci_path
    assert_no_match "Owner's focus", response.body
    get reading_path("isaiah-kjv", 40, 3)
    assert_no_match "Owner's private thought", response.body
  end

  test "another reader's note can't be shown, edited, changed or deleted" do
    @other.foci.start!(title: "Other's focus")
    sign_in_as @other

    get note_path(@owner_note)
    assert_response :not_found
    get edit_note_path(@owner_note)
    assert_response :not_found
    patch note_path(@owner_note), params: { note: { content: "Hijacked" } }
    assert_response :not_found
    assert_no_difference -> { Note.count } do
      delete note_path(@owner_note)
    end
    assert_response :not_found
    assert_match "Owner's private thought", @owner_note.reload.content.to_plain_text
  end

  test "another reader's focus can't be edited or restored" do
    sign_in_as @other
    get edit_focus_path(@owner_focus)
    assert_response :not_found
    patch focus_path(@owner_focus), params: { focus: { title: "Hijacked" } }
    assert_response :not_found
    patch restore_focus_path(@owner_focus)
    assert_response :not_found
    assert_equal "Owner's focus", @owner_focus.reload.title
  end

  test "saving a position moves only the reader's own focus" do
    other_focus = @other.foci.start!(title: "Other's focus")
    sign_in_as @other
    patch position_path, params: { unit_id: verse(5).id }
    assert_equal verse(5), other_focus.reload.last_unit
    assert_nil @owner_focus.reload.last_unit
  end

  test "the work page marks only the reader's own notes" do
    @other.foci.start!(title: "Other's focus")
    sign_in_as @other
    get work_path("isaiah-kjv")
    assert_select "nav.chapters a.tick.has", 0

    sign_in_as @owner
    get work_path("isaiah-kjv")
    assert_select "nav.chapters a.tick.has", 1
  end

  test "an admin can't read other readers' notes either" do
    assert @owner.admin?
    @other.foci.start!(title: "Other's focus")
    @other.foci.current_one.notes.create!(unit: verse(2), content: "Other's private thought")
    sign_in_as @owner

    get notes_path
    assert_no_match "Other's private thought", response.body
    get export_notes_path
    assert_no_match "Other's private thought", response.body
  end
end
