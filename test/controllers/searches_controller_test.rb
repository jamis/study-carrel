require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n2. And God saw the light, that it was good.\n").load
    TextLoader.new("work: Walden\nauthor: Henry David Thoreau\nauthor_short: Thoreau\nunit: paragraph\ncollection: prose\nposition: 1\n\nsection: 1\nlabel: Economy\n1. The light <b>which</b> puts out our eyes.\n").load
    sign_in_as users(:one)
  end

  test "an empty search shows the box and a hint" do
    get search_path
    assert_response :success
    assert_select "input[type=search][name=q][autofocus]"
    assert_select ".search-hint"
  end

  test "results link to the passage, with the matches marked and the text escaped" do
    get search_path(q: "light")
    assert_select ".search-summary", text: /3 passages/
    assert_select "a.fv-ref[href=?]", reading_path("genesis-kjv", 1, 2), text: "Genesis 1:2"
    assert_select "a.fv-ref[href=?]", reading_path("walden", 1, 1), text: "Walden: Economy, paragraph 1 · Thoreau"
    assert_select ".search-excerpt mark", text: "light", count: 3
    assert_select ".search-excerpt b", count: 0
    assert_includes response.body, "&lt;b&gt;which&lt;/b&gt;"
  end

  test "the per-work counts narrow the search to that work" do
    get search_path(q: "light")
    assert_select "details.search-works[open] summary", text: "In 2 works"
    assert_select ".search-counts a[href=?]", search_path(q: "light", work: "genesis-kjv"), text: "Genesis 2"

    get search_path(q: "light", work: "genesis-kjv")
    assert_select ".search-summary", text: /2 passages/
    assert_select "input[type=hidden][name=work][value=genesis-kjv]"
    assert_select ".search-scopes .chip.current", text: "Genesis"
    assert_select ".search-scopes a[href=?]", search_path(q: "light", collection: "bible"), text: "Bible"
    assert_select ".search-scopes a[href=?]", search_path(q: "light"), text: "Whole library"
  end

  test "a long list of works starts folded" do
    13.times { |i| TextLoader.new("work: Extra #{i}\n\nsection: 1\n1. light\n").load }
    get search_path(q: "light")
    assert_select "details.search-works:not([open]) summary", text: "In 15 works"
  end

  test "a collection search covers the collections nested in it" do
    get search_path(q: "light", collection: "sacred-texts")
    assert_select ".search-summary", text: /2 passages/
  end

  test "nothing found, and an unknown place" do
    get search_path(q: "darkness")
    assert_select ".page-empty", text: /Nothing matches darkness/

    get search_path(q: "light", work: "nope")
    assert_response :not_found
  end

  test "the library pages search in their own place" do
    get library_path
    assert_select "form.search-form[action=?]", search_path
    get collection_path("bible")
    assert_select "form.search-form input[type=hidden][name=collection][value=bible]"
    get work_path("walden")
    assert_select "form.search-form input[type=hidden][name=work][value=walden]"
  end

  test "the boxes say they find words in the texts, not titles" do
    get library_path
    assert_select "input[type=search][placeholder=?][aria-label=?]", "Find words in the library", "Find words in the library"
    get collection_path("prose")
    assert_select "input[type=search][placeholder=?]", "Find words in Prose"
    get work_path("walden")
    assert_select "input[type=search][placeholder=?]", "Find words in Walden"
    get search_path
    assert_select ".search-hint", /not titles/
  end

  test "the whole library is a chip of its own, with somewhere else beside it" do
    get search_path(q: "light")
    assert_select ".search-scopes .chip.current", text: "Whole library"
    assert_select ".search-scopes .chip-else", text: "Somewhere else…"
    assert_select ".scope-found a[data-name=Genesis][href=?]", search_path(q: "light", work: "genesis-kjv") do
      assert_select "small", text: /Old Testament · KJV\z/
    end
    assert_select ".scope-found a[data-name=Prose][href=?]", search_path(q: "light", collection: "prose")
  end

  test "the rail's Search opens on the page's own place, or else the place last searched, or the work last read" do
    get work_path("walden")
    assert_select ".rail-search[href=?][aria-label=?]", search_path(work: "walden"), "Search, in Walden"

    get kept_path
    assert_select ".rail-search[href=?]", search_path

    Visit.record(users(:one), Unit.joins(section: :work).find_by!(works: { slug: "genesis-kjv" }))
    get kept_path
    assert_select ".rail-search[href=?]", search_path(work: "genesis-kjv")

    get search_path(q: "light", collection: "bible")
    get kept_path
    assert_select ".rail-search[href=?] .rail-dest", search_path(collection: "bible"), text: "in Bible"
    assert_select ".menu-item[href=?] .menu-note", search_path(collection: "bible"), text: "Bible"

    get search_path(q: "light")
    get kept_path
    assert_select ".rail-search[href=?] .rail-dest", search_path, text: "in the library"
  end

  test "the picker offers shelves and the places searched lately, leaving out those already chips" do
    shelf = users(:one).shelves.create!(name: "Poets I love")
    get search_path(q: "light", collection: "bible")
    get search_path(q: "light", shelf: shelf.slug)
    get search_path(q: "light", work: "walden")
    assert_select ".scope-group a.scope-item", text: /Poets I love/, count: 1
    assert_select ".scope-group a.scope-item[href=?]", search_path(q: "light", collection: "bible"), text: "Bible"
    assert_select ".scope-group a.scope-item", text: "Walden", count: 0
    assert_select ".scope-group a.scope-item", text: "Whole library", count: 0

    shelf.destroy
    get kept_path
    assert_select ".rail-search[href=?]", search_path(work: "walden")
    get search_path(q: "light")
    assert_response :success
  end

  test "signed out, search is closed" do
    sign_out
    get search_path(q: "light")
    assert_redirected_to new_session_path
  end
end
