require "application_system_test_case"

class DeletingSystemTest < ApplicationSystemTestCase
  setup do
    load_isaiah
    @old = users(:one).foci.start!(title: "Rest", description: "Sabbath as a refusal of Pharaoh's economy.")
    @old.notes.create!(unit: verse(3), content: "Stillness").label!("quiet")
    @old.notes.create!(content: "Across them")
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "deleting a focus from its card, after a look at what goes with it" do
    visit foci_path
    within(".card-past") { click_on "Delete" }
    assert_selector "h1", text: "Delete this focus?"
    assert_selector ".delete-card", text: "Rest"
    assert_selector ".delete-what", text: "2 notes go with it"
    click_on "Cancel"
    assert_selector ".card-past", text: "Rest"

    within(".card-past") { click_on "Delete" }
    click_on "Delete this focus"
    assert_selector ".focus-toast", text: "Deleted “Rest”"
    assert_no_selector ".card", text: "Rest"
    assert_selector ".card-current", text: "Holy"
  end
end
