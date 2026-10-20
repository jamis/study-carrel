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

  test "finding what goes with a note: into a group of its, a new group of two, naming one, and back" do
    visit focus_notes_path(@focus)
    assert_selector ".rr-row.here", text: "The withering"

    keys "g"
    within(".rr-cmp-card") do
      assert_selector ".rr-ref", text: /Isaiah 40:7/i
      assert_selector ".cmp-group", count: 1
      assert_selector ".cmp-group .lf-like", text: /like Isaiah 40:6/i
      assert_selector ".cmp-with", text: "with 40:6"
    end
    assert_no_selector ".rr-row.here", visible: true

    # j to 40:6 (already in group 1), then 40:8: put it in group 1.
    keys "j", "j"
    assert_selector ".rr-row.cursor", text: "The word stands"
    keys "1"
    assert_selector ".rr-row.cursor .cmp-put.on", text: "1"
    assert_selector ".rr-cmp-card .cmp-with", text: "with 40:6, 40:8"
    assert_equal [ @group ], @stands.labels.reload

    # On to 40:13: a new group of the two.
    keys "j", "+"
    assert_selector ".rr-cmp-card .cmp-group", count: 2
    new_group = (@counsel.labels.reload & @wither.labels.reload).sole
    assert_nil new_group.name
    assert_selector ".rr-cmp-card .cmp-group:nth-child(2) .lf-like", text: /like Isaiah 40:13/i

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

  test "the card keeps its passage to a line, opening it with p; Esc closes it, then goes back" do
    measured = @focus.notes.create!(unit: verse(12), content: "The scale is the point")
    @focus.update!(reread_note: measured)
    visit focus_notes_path(@focus)
    click_on "Find what goes with this"
    assert_selector ".rr-cmp-card .peek-passage:not(.fits)"
    keys "p"
    assert_selector ".rr-cmp-card .peek-passage.open .peek-full", text: "weighed the mountains in scales"
    keys :escape
    assert_no_selector ".rr-cmp-card .peek.open"
    assert_selector ".comparing"
    keys :escape
    assert_no_selector ".comparing"
  end

  test "holding other notes under tabs: back and forth between them, the one used longest ago giving way, x letting one go" do
    visit focus_notes_path(@focus)
    keys "g"
    assert_selector ".cmp-tab", count: 1
    assert_selector ".cmp-tab.on .cmp-tab-ref", text: /40:7/

    # Hold this, on a row: under a tab of its own; the note left is back in the list, held.
    find(".rr-row", text: "Who hath directed").find(".rr-cmp-hold").click
    assert_selector ".rr-cmp-card .cmp-head .rr-ref", text: /Isaiah 40:13/i
    assert_equal %w[40:7 40:13], all(".cmp-tab-ref").map { it.text.strip }
    assert_selector ".rr-row", text: "The withering" do |row|
      row.assert_selector ".rr-cmp-hold.rr-held", text: "Held · go to its tab"
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

  test "leaving with notes still held leaves no Hold buttons behind on their rows" do
    visit focus_notes_path(@focus)
    keys "g"
    find(".rr-row", text: "Who hath directed").find(".rr-cmp-hold").click
    find(".rr-row", text: "The word stands").find(".rr-cmp-hold").click
    assert_selector ".rr-cmp-hold", text: "Held · go to its tab", count: 2

    find(".rr-cmp-card .cmp-close").click
    assert_no_selector ".comparing"
    assert_no_selector ".rr-cmp-hold"
  end

  test "a note's groups as footnotes: a mark after its text, the other notes under it, each shown when pointed at" do
    whole = @focus.notes.create!(content: "Fading and standing")
    whole.join!(@group)
    visit focus_notes_path(@focus)

    within(".rr-row.here") do
      assert_selector ".rr-fn", text: "40:6"
      assert_selector ".rr-fn .rr-fn-ref", text: "focus 1"
    end
    within("#reread_note_#{@fade.id}") { assert_selector ".rr-text .rr-mark", text: "1" }
    within("#reread_note_#{whole.id}") { assert_selector ".rr-ref", text: /Focus 1 · /i }

    # Pointing at a mark shows the group's other notes; at a reference, that note, to go to.
    find("#reread_note_#{@fade.id} .rr-mark").hover
    within(".fn-pop") do
      assert_text "The withering comes from God too"
      assert_text "Fading and standing"
    end
    find(".rr-row.here .rr-fn-ref", text: "40:6").hover
    within(".fn-pop") do
      assert_text "The voice said, Cry"
      click_on "Go to it"
    end
    assert_selector ".rr-row.here", text: "All flesh is grass"

    # Putting another note in the group adds it to the footnotes of every note in it.
    keys "g", "j", "j", "1"
    assert_selector "#reread_note_#{@stands.id} .rr-fn", text: /40:6\s+40:7/
    assert_selector "#reread_note_#{whole.id} .rr-fn", text: "40:8"
  end
end
