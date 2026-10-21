require "application_system_test_case"

class FocusSheetTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy", description: "Set apart, or near?")
    sign_in_as users(:one)
  end

  test "the focus over the passage shows its description, and nothing to do in it" do
    visit reading_path("isaiah-kjv", 40, 25)
    find(".focus-head").click
    within(".focus-body") do
      assert_text "Set apart, or near?"
      assert_no_selector "a, button"
    end
    find(".now").click
    assert_no_selector ".focus.open"
  end

  test "writing a note on the whole focus from the reader: the next number, in the list and the count" do
    @focus.notes.create!(content: "Holiness keeps arriving as comparison")
    visit reading_path("isaiah-kjv", 40, 25)
    find("body").send_keys "f"
    assert_selector "#sheet_tab_focus[aria-selected=true]"
    within("#sheet_pane_focus") do
      assert_selector ".fs-note", count: 1
      assert_no_selector ".fs-empty"
    end
    assert_selector "#sheet_tab_focus .tab-count", text: "(1)"

    find("body").send_keys "n"
    within("#sheet_pane_focus") do
      assert_no_selector ".fs-new"
      assert_selector ".fs-note.open .fs-meta", text: /Focus 2.*new/im
      find(".fs-note.open lexxy-editor [contenteditable]").send_keys "Every set apart comes with a stooping."
      assert_text "Saved"
      assert_selector ".fs-note.open .fs-meta", text: "FOCUS 2"
      assert_no_selector ".fs-fresh"
    end
    note = @focus.free_notes.last
    assert_equal 2, note.number
    assert_equal "Every set apart comes with a stooping.", note.content.to_plain_text.strip
    assert_selector "#sheet_tab_focus .tab-count", text: "(2)"
    assert_selector "#focus_sheet_all", text: "All 2 notes on this focus"

    # Esc puts it away: the slip comes back, the note at the top of the list.
    find("#sheet_pane_focus .fs-note.open lexxy-editor [contenteditable]").send_keys :escape
    within("#sheet_pane_focus") do
      assert_selector ".fs-new"
      assert_no_selector ".fs-note.open"
      assert_selector ".fs-notes .fs-note:first-child .fs-text", text: "Every set apart comes with a stooping."
    end
  end

  test "opening an earlier note edits it in place; a new one left empty goes" do
    earlier = @focus.notes.create!(content: "Comparison")
    visit reading_path("isaiah-kjv", 40, 25)
    click_on "sheet_tab_focus"
    find("#sheet_pane_focus .fs-note button.fs-open").click
    within("#sheet_pane_focus .fs-note.open") do
      find("lexxy-editor [contenteditable]").send_keys " and contrast"
      assert_text "Saved"
    end
    assert_equal "Comparison and contrast", earlier.reload.content.to_plain_text.strip

    click_on "+ New note"
    assert_selector "#sheet_pane_focus .fs-note.open.fs-unsaved lexxy-editor [contenteditable]"
    assert_selector "#sheet_pane_focus .fs-note:not(.open) .fs-text", text: "Comparison and contrast"
    find(".now").click # leaving it empty
    assert_no_selector "#sheet_pane_focus .fs-unsaved"
    assert_selector "#sheet_pane_focus .fs-new"
    assert_equal 1, @focus.free_notes.count
  end

  test "the tab stays put as the verse changes, and none yet says what they're for" do
    visit reading_path("isaiah-kjv", 40, 25)
    assert_selector "#sheet_tab_unit[aria-selected=true]", text: /40\s*:25/
    click_on "sheet_tab_focus"
    assert_selector "#sheet_pane_focus .fs-empty", text: "What you notice across passages rather than in one"
    find("body").send_keys :right
    assert_selector "#sheet_tab_unit", text: /40\s*:26/
    assert_selector "#sheet_tab_focus[aria-selected=true]"
    assert_selector "#sheet_pane_focus:not([hidden])"
    find("body").send_keys "f"
    assert_selector "#sheet_tab_unit[aria-selected=true]"
    assert_selector "#sheet_pane_unit lexxy-editor"
  end

  test "noting a passage under another focus from the reader, and back" do
    past = @focus
    past.notes.create!(unit: verse(26), content: "Called by name")
    current = users(:one).foci.start!(title: "Waiting")
    current.notes.create!(unit: verse(25), content: "Mine, under Waiting")
    visit reading_path("isaiah-kjv", 40, 25)
    assert_selector "#sheet_pane_unit .lexxy-editor__content", text: "Mine, under Waiting"
    assert_no_selector ".note-also"

    # o drops the focus with the others under it; 1 chooses the first.
    find("body").send_keys "o"
    within(".focus-others") { assert_selector ".pick-title", text: "Holy" }
    find("body").send_keys "1"
    assert_no_selector ".focus.open"
    within("#sheet_pane_unit") do
      assert_selector ".note-under-title", text: "Holy"
      editor = find("lexxy-editor [contenteditable]")
      assert_equal "", editor.text
      editor.send_keys "To whom then: a question, not a wall."
      assert_text "Saved"
    end
    assert_equal "To whom then: a question, not a wall.", past.notes.find_by(unit: verse(25)).content.to_plain_text.strip
    assert_equal "Mine, under Waiting", current.notes.find_by(unit: verse(25)).content.to_plain_text.strip
    assert_equal current, users(:one).foci.current_one

    # Esc goes back to the current focus's note, which now names the other.
    find("#sheet_pane_unit lexxy-editor [contenteditable]").send_keys :escape
    within("#sheet_pane_unit") do
      assert_no_selector ".note-under"
      assert_selector ".lexxy-editor__content", text: "Mine, under Waiting"
      assert_selector ".note-also", text: "Also noted under Holy"
    end

    # A new verse goes back too; "also under" opens that note here.
    find("body").send_keys :right
    within("#sheet_pane_unit") do
      click_on "Holy"
      assert_selector ".note-under-title", text: "Holy"
      assert_selector ".lexxy-editor__content", text: "Called by name"
    end
    find("body").send_keys :right
    assert_no_selector ".note-under"
  end

  test "with another focus, the focus drops even without a description" do
    users(:one).foci.start!(title: "Bare")
    visit reading_path("isaiah-kjv", 40, 25)
    find(".focus-head").click
    assert_selector ".focus-others .pick-title", text: "Holy"
    assert_no_selector ".focus-body-in"
  end
end
