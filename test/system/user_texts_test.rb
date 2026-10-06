require "application_system_test_case"

class UserTextsTest < ApplicationSystemTestCase
  JOURNAL = <<~TEXT
    # 3 March 2024

    Woke before six and sat with the lamp for a while. The house has a particular quiet at that hour.
    "They shall mount up with wings as eagles." I keep wondering what it costs to wait like that.

    # 10 March 2024

    Long walk by the reservoir with M. We talked about her father.
    March 14
    Couldn't sleep. Played Sgt\\. Pepper, loud.
  TEXT

  setup do
    users(:one).foci.start!(title: "What does it mean to wait?")
    sign_in_as users(:one)
  end

  test "add a text: review how it reads, look at a check, then read it" do
    visit library_path
    click_on "Add a text"
    fill_in "Title", with: "Journal, spring 2024"
    fill_in "user_text[source]", with: JOURNAL
    click_on "Review"

    assert_text "2 sections · 5 paragraphs · 8 sentences"
    assert_text "Not split after “M.”"
    find(".texts-check", text: "Looks like a heading").click
    assert_selector ".texts-preview-ref", text: "Journal, spring 2024: 10 March 2024 2:1"
    assert_selector ".texts-preview-text", text: "March 14"
    find("body").send_keys(:arrow_right)
    assert_selector ".texts-preview-text", text: "Couldn't sleep."

    click_on "Edit the text"
    assert_field "Title", with: "Journal, spring 2024"
    click_on "Review"
    click_on "Add to your texts"

    assert_text "Woke before six"
    assert_selector ".now .ref-unit", text: "1:1"
    visit texts_path
    assert_text "Journal, spring 2024"
  end
end
