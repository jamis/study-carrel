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

  test "the band steps through the results, by the reader within a chapter and on into the next, and back lands on the one you're on" do
    TextLoader.new("work: Lamps\n\nsection: 1\n1. A light.\n2. Dark.\n3. A light again.\n\nsection: 2\n1. Dark.\n2. Light at last.\n").load
    visit search_path(q: "light", work: "lamps")
    click_on "Lamps 1:1"
    within(".back-slip-results") do
      assert_text "1 of 3"
      assert_no_selector ".back-slip-step[aria-label^='Previous']"
      assert_selector ".back-slip-step[aria-label='Next result: Lamps 1:3 (])']"
    end

    find("body").send_keys("]")
    assert_selector ".ref", text: /Lamps 1:3/i
    assert_current_path reading_path("lamps", 1, 3)
    within(".back-slip-results") { assert_text "2 of 3" }

    find("body").send_keys("j")
    assert_current_path reading_path("lamps", 2, 1)
    within(".back-slip-results") do
      assert_text "between 2 and 3 of 3"
      assert_selector ".back-slip-step[aria-label='Previous result: Lamps 1:3 ([)']"
    end
    find("body").send_keys("]")
    assert_selector ".ref", text: /Lamps 2:2/i
    within(".back-slip-results") { assert_text "3 of 3" }
    assert_no_selector ".back-slip-step[aria-label^='Next']"

    find("body").send_keys("[")
    assert_current_path reading_path("lamps", 1, 3)
    within(".back-slip") { click_on "Back to results for light" }
    assert_selector ".search-result.returned", text: /Lamps 1:3/i
  end

  test "the matches are marked in the passage, the grid and the whole paragraph, until the band is put away" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    within(".now") { assert_selector "mark", text: "light", count: 1 }
    assert_equal 2, evaluate_script("document.querySelectorAll('.cell.found').length")

    find(".back-slip-x").click
    assert_no_selector ".now mark"
    assert_equal 0, evaluate_script("document.querySelectorAll('.cell.found').length")
  end

  test "reading clause by clause, the matches are marked across the whole passage" do
    TextLoader.new("work: Lamps\n\nsection: 1\n1. A lamp unto my feet, and a light unto my path.\n").load
    visit search_path(q: "light", work: "lamps")
    click_on "Lamps 1:1"
    within(".now") { assert_selector "mark", text: "light" }
    find("body").send_keys(";")
    within(".now") do
      assert_selector ".clause.current", text: "A lamp unto my feet,"
      assert_selector ".clause:not(.current) mark", text: "light"
    end
  end

  test "in prose the whole paragraph marks the matches too" do
    TextLoader.new("work: Walden\nunit: sentence\ngroup: paragraph\n\nsection: 1\nlabel: Economy\n1.1 I went to the woods.\n1.2 The light was low.\n1.3 Dark came.\n").load
    visit search_path(q: "light", work: "walden")
    find(".fv-ref", match: :first).click
    within(".now") { assert_selector "mark", text: "light" }
    find("body").send_keys("k")
    within(".now") { assert_no_selector "mark" }
    find("body").send_keys("p")
    within(".whole-group") do
      assert_selector "a.current", text: "I went to the woods."
      assert_selector "mark", text: "light", count: 1
    end
  end

  test "the way back goes when put away, or when you leave the reader" do
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    assert_selector ".back-slip"
    tops = "['.focus', '.now'].map((s) => document.querySelector(s).getBoundingClientRect().top)"
    with_band = evaluate_script(tops)
    find(".back-slip-x").click
    assert_no_selector ".back-slip"
    with_band.zip(evaluate_script(tops)).each { |was, now| assert_in_delta was, now, 1, "the band grows up from the focus, which stays put" }
    refresh
    assert_selector ".lectio"
    assert_no_selector ".back-slip"
    with_band.zip(evaluate_script(tops)).each { |was, now| assert_in_delta was, now, 1 }

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

    find(".rail-search").click
    assert_selector ".search-hint"
    assert_field "q", with: ""
    within(".search-last") { click_on "back to the results" }
    assert_selector ".search-result.returned", text: /Genesis 1:2/i
  end

  test "a query with quote marks of its own is named as typed, without more around it" do
    quotes = "getComputedStyle(document.querySelector('%s q')).quotes"
    visit search_path(q: "light")
    click_on "Genesis 1:2"
    within(".back-slip") { assert_link "Back to results for light" }
    assert_not_equal "none", evaluate_script(quotes % ".back-slip"), "a plain query is quoted"

    visit search_path(q: %("let there be"))
    click_on "Genesis 1:1"
    within(".back-slip") { assert_link %(Back to results for "let there be") }
    assert_equal "none", evaluate_script(quotes % ".back-slip")

    find(".rail-search").click
    within(".search-last") { assert_text %(Your last search, "let there be") }
    assert_equal "none", evaluate_script(quotes % ".search-last")
  end

  test "with no search yet, Search opens an empty search" do
    visit reading_path("genesis-kjv", 1)
    find(".rail-search").click
    assert_selector ".search-hint"
    assert_no_selector ".search-last"
  end

  test "Search in the reader opens on the work being read, and / does too" do
    visit reading_path("genesis-kjv", 1)
    find(".rail-btn[aria-label='Search, in Genesis']").click
    assert_field "q", placeholder: "Find words in Genesis"
    assert_selector ".search-scopes .chip.current", text: "Genesis"

    visit reading_path("genesis-kjv", 1)
    assert_selector ".lectio"
    find("body").send_keys("/")
    assert_field "q", placeholder: "Find words in Genesis"
  end

  test "Somewhere else… finds a place by its title and searches there" do
    visit search_path(q: "light")
    click_on "Somewhere else…"
    assert_no_selector ".scope-found"
    fill_in placeholder: "A work or collection…", with: "gen"
    assert_selector ".scope-found .scope-item[aria-selected=true]", text: "Genesis"
    find_field(placeholder: "A work or collection…").send_keys(:enter)
    assert_selector ".search-scopes .chip.current", text: "Genesis"
    assert_field "q", with: "light"
    assert_selector ".search-summary", text: /2 passages/

    click_on "Somewhere else…"
    fill_in placeholder: "A work or collection…", with: "nothing like it"
    assert_selector ".scope-none"
    find_field(placeholder: "A work or collection…").send_keys(:escape)
    assert_no_selector ".scope-pop"
  end
end
