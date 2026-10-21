require "application_system_test_case"

class ArchivingTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @old = users(:one).foci.start!(title: "Rest")
    @old.notes.create!(unit: verse(3), content: "Stillness").label!("quiet")
    @old.notes.create!(unit: verse(25), content: "Nothing like it")
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "archiving a focus, undoing it, archiving it again and unarchiving it from the archive" do
    visit foci_path
    within(".card-past") { click_on "Archive" }
    assert_no_selector ".card", text: "Rest"
    assert_selector ".focus-toast", text: "Archived “Rest”"
    within(".focus-toast") { click_on "Undo" }
    assert_selector ".card-past", text: "Rest"
    assert_no_selector ".focus-toast"

    within(".card-past") { click_on "Archive" }
    click_on "Archived focuses"
    assert_selector "h1", text: "Archived focuses"
    within(".card-archived", text: "Rest") { click_on "Unarchive" }
    assert_selector ".page-empty", text: "Nothing archived."
    assert_selector ".focus-toast", text: "back among your focuses"
    assert_not @old.reload.archived?
  end

  test "an archived focus's notes page: reading, but not labelling or writing" do
    @old.archive!
    visit focus_notes_path(@old)
    assert_selector ".rr-row.here", text: "Stillness"
    assert_selector ".rr-row.here .rr-fn-name", text: "quiet"

    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "Nothing like it"
    find("body").send_keys "l"
    find("body").send_keys "n"
    find("body").send_keys "g"
    assert_selector ".rr-picker", visible: :hidden
    assert_no_selector ".rr-row.rr-unsaved"
    assert_no_selector "main.comparing"

    find("body").send_keys "c"
    within(".rr-labels-panel") { click_on "quiet" }
    assert_equal [], @old.notes.find_by!(unit: verse(25)).labels.to_a

    find("body").send_keys "s"
    assert_selector ".reread-pad .rr-pad-read", text: "Nothing in the scratchpad."

    within(".rr-archived") { click_on "Unarchive" }
    assert_no_selector ".rr-archived"
    assert_selector ".page-actions", text: "Edit"
    assert_not @old.reload.archived?
  end
end
