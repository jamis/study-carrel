require "test_helper"

# Archiving a focus puts it away: off the focuses page, onto the archive, its notes read-only until it's unarchived.
class ArchivingTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
    @old = users(:one).foci.start!(title: "Rest")
    @focus = users(:one).foci.start!(title: "Holy", description: "Set apart?")
  end

  test "archiving a card takes it off the focuses page, with Undo, and onto the archive" do
    get foci_path
    assert_select ".card-past form[action=?] button.card-act", archive_focus_path(@old), text: "Archive"
    assert_select ".cards-more", 0

    patch archive_focus_path(@old)
    assert_redirected_to foci_path
    assert @old.reload.archived?
    follow_redirect!
    assert_select ".card .card-title", text: "Rest", count: 0
    assert_select ".cards-more a[href=?]", archived_foci_path, text: /Archived focuses\s*1/
    assert_select ".focus-toast", /Archived “Rest”/
    assert_select ".focus-toast form[action=?]", unarchive_focus_path(@old, undo: 1)

    get archived_foci_path
    assert_select ".card-archived .card-title", "Rest"
    assert_select ".card-archived form[action=?] button", unarchive_focus_path(@old, back: "archived"), text: "Unarchive"
    assert_select ".card-archived .card-pick", 0
  end

  test "Undo puts it back without a word" do
    patch archive_focus_path(@old)
    patch unarchive_focus_path(@old, undo: 1)
    assert_redirected_to foci_path
    assert_not @old.reload.archived?
    follow_redirect!
    assert_select ".focus-toast", 0
  end

  test "archiving the current focus leaves none current: the cards ask you to choose" do
    patch archive_focus_path(@focus)
    assert_nil users(:one).foci.current_one
    follow_redirect!
    assert_select ".card-current", 0
    assert_select ".card-none", /No focus is current/
    assert_select ".card-past .card-title", "Rest"

    get reading_path("isaiah-kjv", 40)
    assert_redirected_to foci_path
    put unit_note_path(verse(3)), params: { note: { content: "x" } }, as: :turbo_stream
    assert_response :conflict

    # Undone straight away, it's current again.
    patch unarchive_focus_path(@focus, undo: 1)
    assert_equal @focus, users(:one).foci.current_one
  end

  test "with every focus archived, the page has only the new card and the way to the archive; reading asks for a new one" do
    patch archive_focus_path(@focus)
    patch archive_focus_path(@old)
    get foci_path
    assert_response :success
    assert_select ".card-none", 0
    assert_select ".card-new"
    assert_select ".cards-more", /2/
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_focus_path
  end

  test "unarchiving from the archive puts it back among the focuses, not current" do
    @old.archive!
    patch unarchive_focus_path(@old, back: "archived")
    assert_redirected_to archived_foci_path
    assert_not @old.reload.archived?
    assert_equal @focus, users(:one).foci.current_one
    follow_redirect!
    assert_select ".page-empty", "Nothing archived."
    assert_select ".focus-toast", /“Rest” is back among your focuses/
  end

  test "an archived focus can't be edited or made current" do
    @old.archive!
    get edit_focus_path(@old)
    assert_response :forbidden
    patch focus_path(@old), params: { focus: { title: "Changed" } }
    assert_response :forbidden
    patch make_current_focus_path(@old)
    assert_response :forbidden
    assert_equal "Rest", @old.reload.title
    assert_equal @focus, users(:one).foci.current_one
  end

  test "an archived focus's notes page is read-only, with Unarchive" do
    note = @old.notes.create!(unit: verse(3), content: "Stillness")
    free = @old.notes.create!(content: "Across them")
    note.label!("quiet")
    @old.update!(scratchpad: "<p>half a thought</p>")
    @old.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "gone")
    @old.archive!

    get focus_notes_path(@old)
    assert_response :success
    assert_select ".page-trail a[href=?]", archived_foci_path, text: "Archived"
    assert_select ".page-actions a[href=?]", edit_focus_path(@old, back: "notes"), 0
    assert_select ".page-actions a[href=?]", export_focus_notes_path(@old)
    assert_select ".rr-archived form[action=?]", unarchive_focus_path(@old, back: "notes")
    assert_select "main[data-controller=?][data-reread-read-only-value=true]", "reread"
    assert_select ".rr-row .rr-note", /Stillness/
    assert_select ".rr-row .rr-chip", "quiet"
    assert_select ".rr-row[data-editor-url]:not([data-editor-url=''])", 0
    assert_select ".rr-chip-x, .rr-add, .rr-find, .rr-new, .rr-cmp-card, .rr-lift", 0
    assert_select ".rr-discard", 0
    assert_select ".reread-pad .rr-pad-read", /half a thought/
    assert_select ".reread-pad form", 0
    assert_select "##{ActionView::RecordIdentifier.dom_id(free, :reread)}"

    get export_focus_notes_path(@old)
    assert_response :success
  end

  test "nothing can be written, labelled, grouped or discarded under an archived focus" do
    note = @old.notes.create!(unit: verse(3), content: "Stillness")
    free = @old.notes.create!(content: "Across them")
    label = note.label!("quiet")
    detached = @old.detached_notes.create!(user: users(:one), citation: "Morning 3", work_title: "Morning", passage: "Grey field.",
                                           reason: "revised", noted_at: 1.day.ago, edited_at: 1.day.ago, content: "gone")
    @old.archive!

    get new_focus_note_path(@old)
    assert_response :forbidden
    get focus_note_path(@old, free)
    assert_response :forbidden
    assert_no_difference "Note.count" do
      post focus_notes_path(@old), params: { note: { content: "<p>More</p>" } }, as: :turbo_stream
    end
    assert_response :forbidden
    put focus_note_path(@old, free), params: { note: { content: "<p>Changed</p>" } }, as: :turbo_stream
    assert_response :forbidden
    put focus_unit_note_path(@old, verse(3)), params: { note: { content: "<p>Changed</p>" } }, as: :turbo_stream
    assert_response :forbidden
    put focus_unit_note_path(@old, verse(8)), params: { note: { content: "<p>New</p>" } }, as: :turbo_stream
    assert_response :forbidden
    assert_equal "Stillness", note.reload.content.to_plain_text
    assert_equal "Across them", free.reload.content.to_plain_text

    post focus_note_labels_path(@old, note), params: { name: "loud" }, as: :turbo_stream
    assert_response :forbidden
    post focus_note_labels_path(@old, free), params: { with_note_id: note.id }, as: :turbo_stream
    assert_response :forbidden
    delete focus_note_label_path(@old, note, label), as: :turbo_stream
    assert_response :forbidden
    patch focus_label_path(@old, label), params: { name: "renamed" }, as: :turbo_stream
    assert_response :forbidden
    assert_equal [ "quiet" ], note.reload.labels.map(&:name)
    assert_equal [], free.reload.labels.to_a

    put focus_scratchpad_path(@old), params: { scratchpad: { content: "Hijacked" } }, as: :json
    assert_response :forbidden
    delete detached_note_path(detached)
    assert_response :forbidden
    assert DetachedNote.exists?(detached.id)

    # Where its reread is up to still moves.
    patch focus_reread_path(@old), params: { note_id: free.id }, as: :json
    assert_response :no_content
  end

  test "in the reader, archived focuses aren't offered to note under, but their notes are still named, read-only" do
    @old.notes.create!(unit: verse(3), content: "Under Rest")
    @old.archive!

    get reading_path("isaiah-kjv", 40, 3)
    assert_select ".focus-body .focus-others", 0
    get unit_foci_path(verse(3))
    assert_select ".pick-title", 0

    get unit_note_path(verse(3)), headers: { "Turbo-Frame" => "note_editor" }
    assert_select ".note-also a.note-also-focus[href=?]", focus_unit_note_path(@old, verse(3)), text: "Rest"

    get focus_unit_note_path(@old, verse(3)), headers: { "Turbo-Frame" => "note_editor" }
    assert_response :success
    assert_select "turbo-frame#note_editor .note-under-archived"
    assert_select "turbo-frame#note_editor .note-read", /Under Rest/
    assert_select "turbo-frame#note_editor form", 0
  end
end
