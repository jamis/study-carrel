require "application_system_test_case"

class CompareTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Waiting")
    @fade = @focus.notes.create!(unit: verse(6), content: "All flesh is grass")
    @wither = @focus.notes.create!(unit: verse(7), content: "The withering comes from God too")
    @stands = @focus.notes.create!(unit: verse(8), content: "The word stands")
    @counsel = @focus.notes.create!(unit: verse(13), content: "Who hath directed the Spirit?")
    @group = @fade.group_with!(@wither)
    @focus.update!(reread_note: @wither)
    sign_in_as users(:one)
  end

  # Keys to the page, not to an element (which Selenium may click first).
  def keys(*keys) = page.driver.browser.action.send_keys(*keys).perform

  test "comparing notes: into a group of its, a new group of two, naming one, and back" do
    visit focus_notes_path(@focus)
    assert_selector ".rr-row.here", text: "The withering"

    keys "g"
    within(".rr-cmp-card") do
      assert_selector ".rr-ref", text: /Isaiah 40:7/i
      assert_selector ".cmp-group", count: 1
      assert_selector ".cmp-group .lf", text: /group A All flesh is grass/i
      assert_selector ".cmp-with", text: "with 40:6"
    end
    assert_no_selector ".rr-row.here", visible: true

    # j to 40:6 (already in group 1), then 40:8: put it in group 1.
    keys "j", "j"
    assert_selector ".rr-row.cursor", text: "The word stands"
    keys "1"
    assert_selector ".rr-row.cursor .rr-cmp-tools .rr-cmp-acts .cmp-put.on", text: "1"
    assert_selector ".rr-cmp-card .cmp-with", text: "with 40:6, 40:8"
    assert_equal [ @group ], @stands.labels.reload

    # On to 40:13: a new group of the two.
    keys "j", "+"
    assert_selector ".rr-cmp-card .cmp-group", count: 2
    new_group = (@counsel.labels.reload & @wither.labels.reload).sole
    assert_nil new_group.name
    assert_selector ".rr-cmp-card .cmp-group:nth-child(2) .lf", text: /group B The withering comes from God too/i

    # Naming it; a name already taken is refused, saying so.
    @fade.label!("fading")
    within(".rr-cmp-card .cmp-group:nth-child(2)") do
      click_on "name it"
      find(".cmp-name").send_keys "Fading", :enter
      assert_text "You already have a label called “Fading”."
      find(".cmp-name").send_keys [ :control, "a" ], "counsel", :enter
    end
    assert_selector ".rr-cmp-card .cmp-group:nth-child(2)", text: "counsel"
    assert_equal "counsel", new_group.reload.name

    # Taking 40:8 back out, with the mouse.
    find(".rr-row", text: "The word stands").find(".cmp-put", text: "1").click
    assert_selector ".rr-cmp-card .cmp-with", text: "with 40:6"
    assert_empty @stands.labels.reload

    # Enter moves the card to the note at the cursor; the × goes back to the reread, on it.
    keys :enter
    assert_selector ".rr-cmp-card .rr-ref", text: /Isaiah 40:13/i
    find(".rr-cmp-card .cmp-close").click
    assert_no_selector ".rr-cmp-card", visible: true
    assert_selector ".rr-row.here", text: "Who hath directed"
    assert_selector ".rr-row.here .rr-chip", text: "counsel"
  end

  test "the card keeps the held note to a line each, the whole entry over it with p or a click; Esc closes it, then goes back" do
    measured = @focus.notes.create!(unit: verse(12), content: "The scale is the point")
    @focus.update!(reread_note: measured)
    visit focus_notes_path(@focus)
    click_on "Compare"
    assert_selector ".rr-cmp-card .cmp-band.cut"
    assert_no_selector ".cmp-entry", visible: true
    keys "p"
    within(".rr-cmp-card .cmp-entry.open") do
      assert_text "weighed the mountains in scales"
      assert_selector ".rr-ref", text: /Isaiah 40:12/i
      assert_text "The scale is the point"
    end
    keys :escape
    assert_no_selector ".cmp-entry", visible: true
    assert_selector ".comparing"

    # A click on either line opens it; a click on it, or moving the cursor, puts it away.
    find(".rr-cmp-card .rr-note.cmp-line").click
    assert_selector ".cmp-entry.open", text: "weighed the mountains in scales"
    find(".cmp-entry").click
    assert_no_selector ".cmp-entry", visible: true
    find(".rr-cmp-card .rr-passage.cmp-line").click
    assert_selector ".cmp-entry.open"
    keys "j"
    assert_no_selector ".cmp-entry", visible: true

    keys :escape
    assert_no_selector ".comparing"
  end

  test "a row's passage cut off opens over it with P or a click; Esc, a click or moving on puts it away" do
    @focus.notes.create!(unit: verse(12), content: "The scale is the point")
    # Narrow enough that 40:12 runs past the two lines a row keeps.
    page.current_window.resize_to(900, 1000)
    visit focus_notes_path(@focus)
    keys "g"
    keys "j", "j", "j"
    assert_selector ".rr-row.cursor", text: "The scale is the point"
    assert_selector ".rr-row.cursor .rr-passage.cut"
    keys "P"
    assert_selector ".rr-row.cursor .rr-peek", text: "and the hills in a balance"
    keys :escape
    assert_no_selector ".rr-peek"
    assert_selector ".comparing"

    find(".rr-row.cursor .rr-passage").click
    assert_selector ".rr-row.cursor .rr-peek"
    keys "j"
    assert_no_selector ".rr-peek"
    assert_selector ".rr-row.cursor", text: "Who hath directed"

    # A click on another row's passage moves the cursor there and opens it; a click on it puts it away.
    find(".rr-row", text: "The scale is the point").find(".rr-passage").click
    assert_selector ".rr-row.cursor .rr-peek", text: "and the hills in a balance"
    find(".rr-peek").click
    assert_no_selector ".rr-peek"
    assert_selector ".rr-row.cursor", text: "The scale is the point"
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  test "comparing with other notes under tabs: back and forth between them, the one used longest ago giving way, x putting one away" do
    visit focus_notes_path(@focus)
    keys "g"
    assert_selector ".cmp-tab", count: 1
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:7/

    # Compare with this, on a row: under a tab of its own; the note left is back in the list, under its tab.
    find(".rr-row", text: "Who hath directed").find(".rr-cmp-hold").click
    assert_selector ".rr-cmp-card .cmp-head .rr-ref", text: /Isaiah 40:13/i
    assert_equal %w[40:7 40:13], all(".cmp-tab-ref").map { it.text.strip }
    assert_selector ".rr-row", text: "The withering" do |row|
      row.assert_selector ".rr-cmp-hold.rr-held", text: "Comparing · go to its tab"
    end

    keys "["
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:7/
    assert_selector ".rr-row.here", text: "The withering", visible: :all
    keys "]"
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:13/

    # A third with Enter; a fourth sends away the one used longest ago (40:7), not the one you're on.
    find(".rr-row", text: "The word stands").click
    keys :enter
    assert_equal %w[40:7 40:13 40:8], all(".cmp-tab-ref").map { it.text.strip }
    find(".rr-row", text: "All flesh is grass").find(".rr-cmp-hold").click
    assert_equal %w[40:13 40:8 40:6], all(".cmp-tab-ref").map { it.text.strip }
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:6/

    # x lets the note you're on go, onto the tab beside it; letting go of the last leaves.
    keys "x"
    assert_equal %w[40:13 40:8], all(".cmp-tab-ref").map { it.text.strip }
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:8/
    keys "x", "x"
    assert_no_selector ".comparing"
    assert_selector ".rr-row.here", text: "Who hath directed"
  end

  test "leaving with notes still under tabs leaves no Compare with this buttons behind on their rows" do
    visit focus_notes_path(@focus)
    keys "g"
    find(".rr-row", text: "Who hath directed").find(".rr-cmp-hold").click
    find(".rr-row", text: "The word stands").find(".rr-cmp-hold").click
    assert_selector ".rr-cmp-hold", text: "Comparing · go to its tab", count: 2

    find(".rr-cmp-card .cmp-close").click
    assert_no_selector ".comparing"
    assert_no_selector ".rr-cmp-hold"
  end

  test "a note's labels as pills on every note, and a note on the card shown when pointed at" do
    whole = @focus.notes.create!(content: "Fading and standing")
    whole.join!(@group)
    visit focus_notes_path(@focus)

    within(".rr-row.here") { assert_selector ".rr-chip .lf", exact_text: "group A" }
    within("#reread_note_#{@fade.id}") do
      assert_selector ".rr-chip .lf", exact_text: "group A"
      assert_no_selector ".rr-chip-take"
    end
    within("#reread_note_#{@stands.id}") { assert_no_selector ".rr-chip" }
    within("#reread_note_#{whole.id}") { assert_selector ".rr-ref", text: /Focus 1 · /i }

    # On the Compare card, pointing at one of a group's notes shows it, to compare with.
    keys "g"
    find(".rr-cmp-card .cmp-jump", text: "40:6").hover
    within(".fn-pop") do
      assert_text "The voice said, Cry"
      click_on "Compare with this"
    end
    assert_selector ".rr-cmp-card .cmp-tab.on", text: "40:6"

    # Putting another note in the group gives it the pill.
    find("#reread_note_#{@stands.id} .cmp-put[data-put='#{@group.id}']").click
    assert_selector "#reread_note_#{@stands.id} .rr-chip .lf", exact_text: "group A"
  end
end
