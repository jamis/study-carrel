require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n2. And there was light.\n\nsection: 2\n1. The heavens.\n").load
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "Search in the rail goes back to the last search, at the result you opened" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".lectio"
    visit reading_path("genesis-kjv", 2)

    find(".rail-btn[aria-label='Search']").click
    assert_field "q", with: "light"
    assert_selector ".search-result.returned", text: /Genesis 1:2/i
    assert_selector ".search-result.returned", count: 1
  end

  test "with no search yet, Search opens an empty search" do
    visit reading_path("genesis-kjv", 1)
    find(".rail-btn[aria-label='Search']").click
    assert_selector ".search-hint"
  end
end
