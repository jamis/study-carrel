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
    visit focus_notes_path(@focus)
    click_on "Find what goes with this"
    assert_selector ".rr-cmp-card .peek-passage:not(.fits)"
    keys "p"
    assert_selector ".rr-cmp-card .peek-passage.open .peek-full", text: "surely the people is grass"
    keys :escape
    assert_no_selector ".rr-cmp-card .peek.open"
    assert_selector ".comparing"
    keys :escape
    assert_no_selector ".comparing"
  end
end
