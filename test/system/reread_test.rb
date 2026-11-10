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

  # Keys to whatever has the focus (an editor, or the page), not to an element (which Selenium may click first).
  def keys(*keys) = page.driver.browser.action.send_keys(*keys).perform

  test "every note in full, numbered, nothing lit; stepping through them, labelling one, and the cloud" do
    visit focus_notes_path(@focus)
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_no_selector ".rr-cursor-on"
    assert_selector ".rr-row:first-child .rr-num", text: "1\nof 2"
    assert_selector ".rr-row", text: "The incomparable"

    find("body").send_keys "l" # with no cursor and nothing pointed at, on the note at the top of the window
    assert_selector ".rr-cursor-on .rr-row.here", text: "The wilderness"
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
      assert_selector ".rr-word", text: "set apart"
      assert_no_selector "[aria-current], .on" # nothing marked until a label is reread, the note's labels neither
      click_on "Empty places" # rereads only its notes, not labelling the one you're on
    end
    assert_selector ".rr-filter.on", text: "the 1 note labelled “Empty places”"
    assert_selector ".rr-row[data-note-id]", count: 1
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_equal [ "set apart" ], @second.labels.reload.map(&:name)
    assert_selector ".reread-pad.labels-open" # kept open through the change of filter
    assert_selector ".rr-labels-panel .rr-word[aria-current]", count: 1

    find(".rr-labels-panel .rr-word[aria-current]", text: "Empty places").click # tapped again, all the notes
    assert_selector ".rr-filter", exact_text: "2 notes ▾"
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_selector ".reread-pad.labels-open"

    find("#reread_note_#{@second.id} .rr-chip-face", text: "set apart").click # a pill too
    assert_selector ".rr-filter.on", text: "the 1 note labelled “set apart”"
    assert_selector ".reread-pad.labels-open"
  end

  test "on a phone, the labels panel is put away as a label in it is reread" do
    page.current_window.resize_to(500, 900)
    visit focus_notes_path(@focus)
    find("body").send_keys "c"
    find(".rr-labels-panel .rr-word", text: "set apart").click
    assert_selector ".rr-filter.on", text: "the 1 note labelled “set apart”"
    assert_no_selector ".reread-pad.labels-open"
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  test "a label in the panel rereads its notes from the note you're on, when it carries it" do
    @first.label!("set apart")
    visit focus_notes_path(@focus, at: @second.id)
    assert_selector ".rr-row.here", text: "The incomparable"
    find("body").send_keys "c"
    within(".rr-labels-panel") do
      assert_selector ".rr-word", text: "set apart"
      click_on "Tallies"
      assert_selector "[data-view=tallies][aria-pressed=true]"
      find(".rr-tally", text: "set apart").click
    end
    assert_selector ".rr-filter.on", text: "the 2 notes labelled “set apart”"
    assert_selector ".rr-row.here", text: "The incomparable"
    assert_selector ".reread-pad.labels-open.show-tallies .rr-tally[aria-current]", text: "set apart"
    assert_no_selector ".rr-ticks i.here"

    find(".rr-tally", text: "set apart").click # all the notes, on this note
    assert_selector ".rr-filter", exact_text: "2 notes ▾"
    assert_selector ".reread-pad.labels-open"
    find(".rr-tally", text: "set apart").click # a page seen before, which Turbo previews from its cache first
    assert_selector ".rr-filter.on", text: "the 2 notes labelled “set apart”"
    assert_no_selector "html[data-turbo-preview]"
    assert_selector ".reread-pad.labels-open"
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

    find("body").send_keys :escape # the cursor away first
    assert_no_selector ".rr-cursor-on"
    assert_selector ".rr-filter-band"
    find("body").send_keys :escape
    assert_no_selector ".rr-filter-band"
    assert_selector ".rr-row[data-note-id]", count: 3
    assert_selector ".rr-row.here", text: "The wilderness"
  end

  test "rereading the notes without a label: one labelled stays until you move on, then leaves the run" do
    third = @focus.notes.create!(unit: verse(31), content: "Renewed")
    visit focus_notes_path(@focus)
    find(".rr-filter").click
    within(".rr-filter-menu") { click_on "Without a label" }
    assert_selector ".rr-filter-band", text: "Only the 2 notes without a label"
    assert_selector ".rr-row[data-note-id]", count: 2
    find(".rr-filter").click
    assert_selector ".rr-filter-menu .menu-item[aria-current=page]", text: "Without a label"
    find(".rr-filter").click
    assert_selector ".rr-row.here", text: "The wilderness"

    find("body").send_keys "l"
    find(".rr-picker input").send_keys "Empty places", :enter
    assert_selector ".rr-row.here .rr-chip", text: "Empty places"
    assert_selector ".rr-filter-band", text: "Only the 1 note without a label · 1 just labelled"

    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "Renewed"
    assert_no_selector ".rr-row", text: "The wilderness"
    assert_selector ".rr-filter-band", text: "Only the 1 note without a label"
    assert_no_selector ".rr-filter-band", text: "just labelled"

    find("body").send_keys "l"
    find(".rr-picker input").send_keys "Empty places", :enter
    assert_selector ".rr-row.here .rr-chip", text: "Empty places"
    find("body").send_keys "k" # nowhere to go: it stays
    assert_selector ".rr-row.here", text: "Renewed"
    assert_selector ".rr-filter-band", text: "Only the 0 notes without a label · 1 just labelled"

    find("body").send_keys :escape, :escape # the cursor away, then back to all the notes
    assert_no_selector ".rr-filter-band"
    assert_selector ".rr-row[data-note-id]", count: 3
    assert_selector ".rr-row.here", text: "Renewed"
    assert_equal [ "Empty places" ], third.labels.reload.map(&:name)
  end

  test "removing the label from its last note, then leaving for all the notes" do
    group = @first.group_with!(@second)
    @second.unlabel!(group)
    visit focus_notes_path(@focus, label: group.id)
    assert_selector ".rr-filter-band", text: "Only the 1 note in group A"
    find(".rr-row.here").hover # Remove is on the pill of the note pointed at
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
    find(".rr-row.here").hover
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

  test "naming an unnamed group from its band, then renaming it; a name already taken is refused" do
    group = @first.group_with!(@second)
    visit focus_notes_path(@focus, label: group.id)
    assert_selector ".rr-filter-band", text: "Only the 2 notes in group A"

    within(".rr-filter-band") { click_on "Name it" }
    find(".rr-name").send_keys "Set apart", :enter
    assert_selector ".rr-name-error", text: "You already have a label called “Set apart”."
    find(".rr-name").send_keys :escape
    assert_selector ".rr-filter-band", text: "Only the 2 notes in group A"
    assert_selector ".rr-filter-band", text: "Name it"
    assert_nil group.reload.name

    find("body").send_keys "r"
    find(".rr-name").send_keys "wilderness", :enter
    assert_selector ".rr-filter-band", text: "Only the 2 notes labelled “wilderness”"
    assert_selector ".rr-filter-band", text: "Rename"
    assert_selector ".rr-filter.on", text: "the 2 notes labelled “wilderness”"
    assert_selector ".rr-row .rr-chip.current", text: "wilderness", count: 2
    assert_equal "wilderness", group.reload.name

    within(".rr-filter-band") { click_on "Rename" }
    assert_equal "wilderness", find(".rr-name").value
    find(".rr-name").send_keys [ :control, "a" ], :backspace, :enter
    assert_selector ".rr-filter-band", text: "Only the 2 notes in group A"
    assert_nil group.reload.name
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
    find("body").send_keys "j" # the cursor up, on the note at the top
    assert_selector ".rr-cursor-on .rr-row.here", text: "The wilderness"
    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "The incomparable"
  end

  test "opens at the top, not where you were; with no cursor, l acts on the note in view, not on one out of sight" do
    (4..24).each { |n| @focus.notes.create!(unit: verse(n), content: "Note on verse #{n}") }
    @focus.notes.create!(content: "Across it all")
    visit focus_notes_path(@focus)
    find(".rr-row", text: "Across it all").hover
    within(".rr-row", text: "Across it all") { click_on "+ label" }
    keys :escape, :escape # the picker, then the cursor
    assert_no_selector ".rr-cursor-on"

    # Scrolled back to the top, l labels the note there, not the one acted on last (far below).
    page.execute_script("scrollTo(0, 0)")
    find("h1").hover # pointing at no note
    find("body").send_keys "l"
    assert_selector ".rr-cursor-on .rr-row.here", text: "The wilderness"
    keys :escape, :escape

    visit foci_path
    find(".card-notes a[href='#{focus_notes_path(@focus)}']", match: :first).click # a Turbo visit
    assert_selector ".rr-row.here", text: "The wilderness"
    assert_no_selector ".rr-cursor-on"
    sleep 0.3
    assert_equal 0, page.evaluate_script("scrollY")
  end

  test "the scratchpad is put away behind its tab, and saves as you write" do
    visit focus_notes_path(@focus)
    assert_no_selector ".reread-pad lexxy-editor [contenteditable]"
    find(".rr-edge-tab", text: /scratchpad/i).click
    find(".reread-pad lexxy-editor [contenteditable]").send_keys "Compare Amos 5?"
    within(".reread-pad") { assert_text "Saved" }
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text.strip
  end

  test "the current focus's note can be edited where it stands, with Edit or e; Esc puts the editor away" do
    visit focus_notes_path(@focus)
    assert_no_selector "lexxy-editor"
    find(".rr-row", text: "The incomparable").hover
    within(".rr-row", text: "The incomparable") { click_on "Edit" }
    within(".rr-row.here") { find("lexxy-editor [contenteditable]", text: "The incomparable") }
    keys :escape
    assert_no_selector ".rr-row lexxy-editor"
    assert_selector ".rr-cursor-on .rr-row.here", text: "The incomparable"

    keys "k", "e"
    within(".rr-row.here") { find("lexxy-editor [contenteditable]", text: "The wilderness") }
    keys " Met there."
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

    # Moving on shows its text in the row, and editing it again opens its editor on it, not on a new note.
    keys :escape
    assert_no_selector ".rr-row lexxy-editor"
    keys "k"
    assert_selector "#reread_note_#{note.id}:not(.here) .rr-note", text: "Holiness keeps stooping."
    keys "j"
    assert_selector ".rr-row.here#reread_note_#{note.id}"
    keys "e"
    within(".rr-row.here#reread_note_#{note.id}") { assert_selector "lexxy-editor [contenteditable]", text: "Holiness keeps stooping." }
    assert_equal 1, @focus.free_notes.count

    keys :escape, "l"
    find(".rr-picker input").send_keys "the poor", :enter
    assert_selector ".rr-row.here .rr-chip", text: "the poor"
    assert_equal [ "the poor" ], note.labels.reload.map(&:name)

    keys "n"
    assert_selector ".rr-row.here.rr-unsaved"
    keys :escape, "k"
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
