require "application_system_test_case"

class SentencesTest < ApplicationSystemTestCase
  setup do
    TextLoader.new(<<~TXT).load
      work: Walden
      unit: sentence
      group: paragraph

      section: 2
      label: Where I Lived
      1.1 I went to the woods because I wished to live deliberately.
      1.2 I did not wish to live what was not life.
      2.1 Our life is frittered away by detail.
      2.2 Simplify, simplify.
    TXT
    users(:one).foci.start!(title: "Deliberately")
    sign_in_as users(:one)
  end

  test "prose steps a sentence at a time, cited by paragraph, with ¶ opening each paragraph" do
    visit reading_path("walden", 2, 1)
    assert_selector ".now .ref-unit", text: "1:1"
    assert_selector ".pilcrow", visible: true

    click_on "Sentence 1:2"
    assert_selector ".now .ref-unit", text: "1:2"
    assert_text "I did not wish to live"
    assert_no_selector ".pilcrow", visible: true
    assert_selector ".step-of", text: "2 of 4"

    find(".step-of").click
    within(".unit-grid") { assert_selector ".grid-group-name", text: "¶ 2" }
    find(".cell[aria-label='Sentence 2:1']").click
    assert_selector ".now .ref-unit", text: "2:1"
    assert_selector ".pilcrow", visible: true
  end

  test "¶ (or p) shows the whole paragraph, and any sentence in it can be chosen" do
    visit reading_path("walden", 2, 3)
    find("body").send_keys "p"
    within(".whole-group") do
      assert_selector "a.current", text: "Our life is frittered away by detail."
      click_on "Simplify, simplify."
    end
    assert_selector ".now .ref-unit", text: "2:2"
    assert_selector ".whole-group a.current", text: "Simplify, simplify."

    find("body").send_keys "p"
    assert_no_selector ".whole-group", visible: true
  end
end
