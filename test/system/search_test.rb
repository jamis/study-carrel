require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n2. And there was light.\n\nsection: 2\n1. The heavens.\n").load
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "a result opened from a search has a way back to it, at that result, while you read on" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".lectio"
    find(".step[aria-label='Genesis 2']").click
    assert_current_path reading_path("genesis-kjv", 2, 1)

    within(".back-slip") { click_on "Back to results for light" }
    assert_field "q", with: "light"
    assert_selector ".search-result.returned", text: /Genesis 1:2/i
    assert_selector ".search-result.returned", count: 1
  end

  test "the way back goes when put away, or when you leave the reader" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".back-slip"
    focus_top = "document.querySelector('.focus').getBoundingClientRect().top"
    with_band = evaluate_script(focus_top)
    find(".back-slip-x").click
    assert_no_selector ".back-slip"
    assert_operator evaluate_script(focus_top), :<, with_band
    closed_up = evaluate_script(focus_top)
    refresh
    assert_selector ".lectio"
    assert_no_selector ".back-slip"
    assert_in_delta closed_up, evaluate_script(focus_top), 1, "the focus is back in its usual place"

    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".back-slip"
    visit kept_path
    visit reading_path("genesis-kjv", 1)
    assert_selector ".lectio"
    assert_no_selector ".back-slip"
  end

  test "Search in the rail opens an empty search, offering the last one" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".lectio"

    find(".rail-btn[aria-label='Search']").click
    assert_selector ".search-hint"
    assert_field "q", with: ""
    within(".search-last") { click_on "back to the results" }
    assert_selector ".search-result.returned", text: /Genesis 1:2/i
  end

  test "with no search yet, Search opens an empty search" do
    visit reading_path("genesis-kjv", 1)
    find(".rail-btn[aria-label='Search']").click
    assert_selector ".search-hint"
    assert_no_selector ".search-last"
  end
end
