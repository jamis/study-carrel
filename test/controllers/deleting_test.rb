require "test_helper"

# Deleting a focus asks first, on a page of its own showing which focus it is and what goes with it; then the focus
# goes, with everything written under it. No Undo.
class DeletingTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
    @old = users(:one).foci.start!(title: "Rest")
    @focus = users(:one).foci.start!(title: "Holy", description: "Set apart?")
  end

  test "every card, archived ones too, has Delete, which only goes to the page that asks" do
    get foci_path
    assert_select ".card-current a.card-act[href=?]", delete_focus_path(@focus), text: "Delete"
    assert_select ".card-past a.card-act[href=?]", delete_focus_path(@old), text: "Delete"

    @old.archive!
    get archived_foci_path
    assert_select ".card-archived a.card-act[href=?]", delete_focus_path(@old), text: "Delete"

    get delete_focus_path(@old)
    assert_response :success
    assert Focus.exists?(@old.id)
  end

  test "the page shows the focus and everything that goes with it, and the ways to keep its notes" do
    @old.notes.create!(unit: verse(3), content: "Stillness")
    @old.notes.create!(unit: verse(8), content: "Grass")
    @old.notes.create!(content: "Across them")
    @old.update!(scratchpad: "<p>half a thought</p>")
    @old.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "gone")

    get delete_focus_path(@old)
    assert_select ".page-trail a[href=?]", foci_path
    assert_select "h1", "Delete this focus?"
    assert_select ".delete-card .card-title", "Rest"
    assert_select ".delete-what strong", "3 notes"
    assert_select ".delete-what li", 4
    assert_select ".delete-what li", "2 notes on passages in Isaiah"
    assert_select ".delete-what li", "1 note on the whole focus"
    assert_select ".delete-what li", "1 more set aside earlier, from passages that changed"
    assert_select ".delete-what li", "its scratchpad"
    assert_select ".delete-final", /can’t be undone/
    assert_select ".delete-final", text: /current/, count: 0
    assert_select ".delete-keep form[action=?]", archive_focus_path(@old)
    assert_select ".delete-keep a[href=?]", export_focus_notes_path(@old)
    assert_select ".delete-actions form[action=?] input[name=_method][value=delete]", focus_path(@old)
    assert_select ".delete-actions a[href=?]", foci_path, text: "Cancel"
  end

  test "a focus with no notes just says so" do
    get delete_focus_path(@focus)
    assert_select ".delete-what", "It has no notes."
    assert_select ".delete-keep", 0
    assert_select ".delete-card .card-label", /Current/
    assert_select ".delete-final", /“Rest” will be current instead/
  end

  test "an archived focus is asked about from the archive and goes back there, without the offer to archive it" do
    @old.notes.create!(unit: verse(3), content: "Stillness")
    @old.archive!

    get delete_focus_path(@old)
    assert_select ".page-trail a[href=?]", archived_foci_path, text: "Archived"
    assert_select ".delete-keep form", 0
    assert_select ".delete-keep a[href=?]", export_focus_notes_path(@old), text: "Download its notes (.md)"
    assert_select ".delete-actions form[action=?]", focus_path(@old, back: "archived")
    assert_select ".delete-actions a[href=?]", archived_foci_path, text: "Cancel"

    delete focus_path(@old, back: "archived")
    assert_redirected_to archived_foci_path
    assert_not Focus.exists?(@old.id)
    follow_redirect!
    assert_select ".focus-toast", /Deleted “Rest”/
    assert_select ".focus-toast form", 0
  end

  test "deleting takes everything written under the focus, and labels no other note carries" do
    note = @old.notes.create!(unit: verse(3), content: "Stillness")
    free = @old.notes.create!(content: "Across them")
    kept = @focus.notes.create!(unit: verse(3), content: "Holy stillness")
    shared = note.label!("quiet")
    kept.label!("quiet")
    only_here = note.label!("only here")
    free.group_with!(note)
    @old.update!(scratchpad: "<p>half a thought</p>")
    @old.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "gone")

    assert_difference -> { Focus.count } => -1, -> { Note.count } => -2, -> { DetachedNote.count } => -1,
                      -> { ActionText::RichText.count } => -4 do
      delete focus_path(@old)
    end
    assert_redirected_to foci_path
    follow_redirect!
    assert_select ".focus-toast", /Deleted “Rest”/

    assert_equal [ "quiet" ], kept.reload.labels.map(&:name)
    assert Label.exists?(shared.id)
    assert_not Label.exists?(only_here.id)
    assert_equal [ shared ], users(:one).labels.to_a
    assert_equal @focus, users(:one).foci.current_one
  end

  test "deleting the current focus makes the next most recent current" do
    delete focus_path(@focus)
    assert_equal @old, users(:one).foci.current_one
    follow_redirect!
    assert_select ".card-current .card-title", "Rest"

    delete focus_path(@old)
    assert_nil users(:one).foci.current_one
    assert_redirected_to foci_path
  end

  test "deleting the current focus passes over an archived one that was current more recently" do
    middle = users(:one).foci.start!(title: "Middle")
    last = users(:one).foci.start!(title: "Last")
    middle.archive!

    get delete_focus_path(last)
    assert_select ".delete-final", /“Holy” will be current instead/
    delete focus_path(last)
    assert_equal @focus, users(:one).foci.current_one

    middle.unarchive!
    assert_equal @focus, users(:one).foci.current_one
  end

  test "with no other focus in use, the page doesn't say which will be current" do
    @old.archive!
    get delete_focus_path(@focus)
    assert_select ".delete-final", "This can’t be undone."
  end

  test "another user's focus is a 404, on the page and the delete" do
    sign_in_as users(:two)
    get delete_focus_path(@old)
    assert_response :not_found
    delete focus_path(@old)
    assert_response :not_found
    assert Focus.exists?(@old.id)
  end
end
