require "application_system_test_case"

class RereadTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @first = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    @second = @focus.notes.create!(unit: verse(25), content: "The incomparable")
    @second.label!("set apart")
    sign_in_as users(:one)
  end

  test "stepping through the notes, labelling one, and the cloud" do
    visit focus_notes_path(@focus)
    assert_selector ".rr-row.here", text: "The wilderness"

    find("body").send_keys "l"
    find(".rr-picker input").send_keys "Empty places", :enter
    assert_selector ".rr-row.here .rr-chip", text: "Empty places"
    assert_equal [ "Empty places" ], @first.labels.reload.map(&:name)
    find(".rr-filter").click
    within(".rr-filter-menu") do
      assert_selector ".menu-item[aria-current=page]", text: "All notes"
      assert_selector ".menu-item", text: "Empty places\n1"
    end
    find(".rr-filter").click

    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "The incomparable"
    assert_selector ".rr-row.here .rr-chip", text: "set apart"

    find("body").send_keys "c"
    within(".rr-labels-panel") do
      assert_selector ".rr-word.on", text: "set apart"
      click_on "Empty places"
    end
    assert_selector ".rr-row.here .rr-chip", text: "Empty places"
    assert_selector ".rr-labels-panel .rr-word.on", text: "Empty places"
    assert_equal [ "Empty places", "set apart" ], @second.labels.reload.map(&:name).sort

    find(".rr-labels-panel .rr-word", text: "set apart").click # tapped again, it comes off
    assert_no_selector ".rr-row.here .rr-chip", text: "set apart"
    assert_no_selector ".rr-labels-panel .rr-word", text: "set apart"
  end

  test "a pill rereads only its label's notes, from that note; there Remove takes it off, to put back until you move on" do
    third = @focus.notes.create!(unit: verse(31), content: "Renewed")
    @first.join!(waiting = third.label!("waiting"))
    visit focus_notes_path(@focus)
    assert_selector ".rr-filter", exact_text: "3 notes ▾"

    find("#reread_note_#{third.id} .rr-chip-face", text: "waiting").click
    assert_selector ".rr-filter.on", text: "the 2 notes labelled “waiting”"
    find(".rr-filter").click
    assert_selector ".rr-filter-menu .menu-item[aria-current=page]", text: "waiting"
    find(".rr-filter").click
    assert_selector ".rr-filter-band", text: "Only the 2 notes labelled “waiting”"
    assert_selector ".rr-row[data-note-id]", count: 2
    assert_selector ".rr-row.here", text: "Renewed"
    sleep 1 # past the position save's debounce
    assert_equal third, @focus.reload.reread_note

    within(".rr-row.here") { click_on "× Remove" }
    assert_selector ".rr-row.here .rr-chip.removed", text: "waiting"
    assert_selector ".rr-filter-band", text: "Only the 1 note labelled “waiting” · 1 just removed"
    within(".rr-row.here") { click_on "Put back" }
    assert_no_selector ".rr-chip.removed"
    assert_selector ".rr-filter-band", text: "Only the 2 notes labelled “waiting”"

    within(".rr-row.here") { click_on "× Remove" }
    find("body").send_keys "k"
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_no_selector ".rr-row", text: "Renewed"
    assert_selector ".rr-filter-band", text: "Only the 1 note labelled “waiting”"
    assert_empty third.labels.reload
    assert_equal [ @first ], waiting.notes.reload

    find("body").send_keys :escape
    assert_no_selector ".rr-filter-band"
    assert_selector ".rr-row[data-note-id]", count: 3
    assert_selector ".rr-row.here", text: "The wilderness"
  end

  test "removing the label from its last note, then leaving for all the notes" do
    group = @first.group_with!(@second)
    @second.unlabel!(group)
    visit focus_notes_path(@focus, label: group.id)
    assert_selector ".rr-filter-band", text: "Only the 1 note in group A"
    within(".rr-row.here") { click_on "× Remove" }
    find(".rr-filter-x").hover
    sleep 0.5 # long enough for Turbo to prefetch it, from before the label came off
    find(".rr-filter-x").click
    assert_no_selector ".rr-filter-band"
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_no_selector ".rr-row.here .rr-chip", text: "group A"
    assert_not Label.exists?(group.id)
  end

  test "following another pill after Remove comes to the note with the label off" do
    waiting = @second.label!("waiting")
    visit focus_notes_path(@focus, label: waiting.id)
    within(".rr-row.here") { click_on "× Remove" }
    face = find(".rr-row.here .rr-chip-face", text: "set apart")
    face.hover
    sleep 0.5 # long enough for Turbo to prefetch it, from before the label came off
    face.click
    assert_selector ".rr-filter-band", text: "labelled “set apart”"
    assert_selector ".rr-row.here", text: "The incomparable"
    assert_no_selector ".rr-row.here .rr-chip", text: "waiting"
    assert_empty waiting.note_labels.reload
  end

  test "the label picker: every label as a cloud, A–Z or recent, and Enter takes the closest match or a new label" do
    %w[ glory grace holiness humility justice mercy peace sorrow wilderness zeal ].each { @second.label!(it) }
    users(:one).foci.create!(title: "Rest", made_current_at: 1.day.ago).notes.create!(unit: verse(31), content: "x").label!("hope")
    visit focus_notes_path(@focus)

    find("body").send_keys "l"
    within(".rr-picker") do
      assert_selector ".rr-pick", count: 12
      assert_selector ".rr-pick.away[title='Under Rest']", text: "hope"
      assert_selector ".rr-pick:first-child", text: "glory"
      assert_no_selector ".rr-pick.chosen"
      assert_text "Type to narrow"

      find("input").send_keys "ho"
      assert_selector ".rr-pick", count: 2
      assert_selector ".rr-pick.chosen", text: "holiness" # starts with it, as hope does, and comes first
      assert_selector ".rr-picker-foot", text: "↵ holiness"
      assert_selector ".rr-pick-new", text: "New label “ho”"

      find("input").send_keys :up, :enter # round from the first label to the new one
    end
    assert_selector ".rr-row.here .rr-chip", exact_text: "ho"

    find("body").send_keys "l"
    within(".rr-picker") do
      click_on "Recent"
      assert_selector ".rr-pick:first-child", text: "hope"
      find("input").send_keys "wild", :enter
    end
    assert_selector ".rr-row.here .rr-chip", text: "wilderness"
    assert_equal %w[ ho wilderness ], @first.labels.reload.map(&:name).sort
  end

  test "opens where it left off" do
    visit focus_notes_path(@focus)
    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "The incomparable"
    sleep 1 # past the position save's debounce
    visit focus_notes_path(@focus)
    assert_selector ".rr-row.here", text: "The incomparable"
  end

  test "coming back to a note far down, it stands in view" do
    (4..24).each { |n| @focus.notes.create!(unit: verse(n), content: "Note on verse #{n}") }
    @focus.update!(reread_note_id: @second.id)
    visit foci_path
    find(".card-notes a[href='#{focus_notes_path(@focus)}']").click # a Turbo visit, which scrolls the page after rendering it
    assert_selector ".rr-row.here", text: "The incomparable"
    sleep 0.3
    assert page.evaluate_script(<<~JS)
      (() => { const box = document.querySelector(".rr-row.here").getBoundingClientRect(); return box.top >= 0 && box.top < innerHeight })()
    JS
  end

  test "opens again on a note on the whole focus, coming back from the focuses page" do
    whole = @focus.notes.create!(content: "Across it all")
    visit focus_notes_path(@focus)
    find(".rr-row", text: "Across it all").click
    assert_selector ".rr-row.here", text: "Across it all"
    sleep 1 # past the position save's debounce
    visit foci_path
    find(".card-notes a[href='#{focus_notes_path(@focus)}']", match: :first).click
    assert_selector ".rr-row.here", text: "Across it all"
    assert_equal whole.id, @focus.reload.reread_note_id
  end

  test "the scratchpad is put away behind its tab, and saves as you write" do
    visit focus_notes_path(@focus)
    assert_no_selector ".reread-pad lexxy-editor [contenteditable]"
    find(".rr-edge-tab", text: /scratchpad/i).click
    find(".reread-pad lexxy-editor [contenteditable]").send_keys "Compare Amos 5?"
    within(".reread-pad") { assert_text "Saved" }
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text.strip
  end

  test "the current focus's note can be edited where it stands" do
    visit focus_notes_path(@focus)
    within(".rr-row.here") { find("lexxy-editor [contenteditable]").send_keys :end, " Met there." }
    within(".rr-row.here") { assert_text "Saved" }
    assert_equal "The wilderness Met there.", @first.reload.content.to_plain_text.strip
  end

  test "writing a note on the whole focus, labelling it, and leaving an empty one behind" do
    visit focus_notes_path(@focus)
    click_on "+ New note"
    within(".rr-row.here") { find("lexxy-editor [contenteditable]").send_keys "Holiness keeps stooping." }
    within(".rr-row.here") { assert_text "Saved" }
    note = @focus.free_notes.sole
    assert_equal "Holiness keeps stooping.", note.content.to_plain_text.strip
    assert_selector ".rr-row.here#reread_note_#{note.id}"

    # Moving on shows its text in the row, and coming back opens its editor on it, not on a new note.
    find("body").send_keys :escape, "k"
    assert_selector "#reread_note_#{note.id}:not(.here) .rr-note", text: "Holiness keeps stooping."
    find("body").send_keys "j"
    within(".rr-row.here#reread_note_#{note.id}") { assert_selector "lexxy-editor [contenteditable]", text: "Holiness keeps stooping." }
    assert_equal 1, @focus.free_notes.count

    find("body").send_keys :escape, "l"
    find(".rr-picker input").send_keys "the poor", :enter
    assert_selector ".rr-row.here .rr-chip", text: "the poor"
    assert_equal [ "the poor" ], note.labels.reload.map(&:name)

    find("body").send_keys "n"
    assert_selector ".rr-row.here.rr-unsaved"
    find("body").send_keys :escape, "k"
    assert_no_selector ".rr-unsaved"
    assert_equal 1, @focus.free_notes.count
  end

  test "making a note of a line in the scratchpad" do
    @focus.update!(scratchpad: "<p>Compare Amos 5?</p>")
    visit focus_notes_path(@focus)
    find("body").send_keys "s"
    assert_selector ".reread-pad .lexxy-editor__content p", text: "Compare Amos 5?"
    execute_script <<~JS
      const line = document.querySelector(".reread-pad .lexxy-editor__content p")
      const range = document.createRange()
      range.selectNodeContents(line)
      getSelection().removeAllRanges()
      getSelection().addRange(range)
    JS
    click_on "Make a note of this"
    assert_text "Made a note on the whole focus."
    assert_selector "#reread_free .rr-row", text: "Compare Amos 5?"
    assert_equal "Compare Amos 5?", @focus.free_notes.sole.content.to_plain_text.strip
    click_on "Go to it"
    assert_selector ".rr-row.here", text: "Compare Amos 5?"
  end
end
