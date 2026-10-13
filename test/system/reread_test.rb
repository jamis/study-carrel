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
    visit focus_reread_path(@focus)
    assert_selector ".rr-row.here", text: "The wilderness"

    find("body").send_keys "l"
    find(".rr-picker input").send_keys "Empty places", :enter
    assert_selector ".rr-row.here .rr-chip", text: "Empty places"
    assert_equal [ "Empty places" ], @first.labels.reload.map(&:name)

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

    find(".rr-row.here .rr-chip", text: "set apart").click_on "×"
    assert_no_selector ".rr-row.here .rr-chip", text: "set apart"
    assert_no_selector ".rr-labels-panel .rr-word", text: "set apart"
  end

  test "opens where it left off" do
    visit focus_reread_path(@focus)
    find("body").send_keys "j"
    assert_selector ".rr-row.here", text: "The incomparable"
    sleep 1 # past the position save's debounce
    visit focus_reread_path(@focus)
    assert_selector ".rr-row.here", text: "The incomparable"
  end

  test "the scratchpad saves as you write" do
    visit focus_reread_path(@focus)
    find(".reread-pad lexxy-editor [contenteditable]").send_keys "Compare Amos 5?"
    within(".reread-pad") { assert_text "Saved" }
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text.strip
  end

  test "the current focus's note can be edited where it stands" do
    visit focus_reread_path(@focus)
    within(".rr-row.here") { find("lexxy-editor [contenteditable]").send_keys :end, " Met there." }
    within(".rr-row.here") { assert_text "Saved" }
    assert_equal "The wilderness Met there.", @first.reload.content.to_plain_text.strip
  end
end
