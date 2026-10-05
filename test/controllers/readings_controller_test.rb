require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    users(:one).foci.start!(title: "What does it mean to be holy?")
    sign_in_as users(:one)
  end

  test "defaults to the first verse" do
    get reading_path("isaiah-kjv", 40)
    assert_response :success
    assert_select ".now .ref", "Isaiah 40:1"
    assert_select ".tick", 31
    assert_select ".tick.current", "1"
  end

  test "the URL selects the verse and its neighbors" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".now", /To whom then will ye liken me/
    assert_select ".near b", text: "24"
    assert_select ".near b", text: "26"
    assert_select ".tick.current", "25"
  end

  test "Random rolls in the innermost collection, with the wider scopes behind a disclosure" do
    get reading_path("isaiah-kjv", 40)
    assert_select ".menu-row a.menu-item[href=?]", random_collection_path("old-testament"), text: /Old Testament/
    assert_select ".menu-sub a.menu-item[href=?]", random_work_path("isaiah-kjv")
    assert_select ".menu-sub a.menu-item[href=?]", random_path
  end

  test "unknown verse is a 404" do
    get reading_path("isaiah-kjv", 40, 99)
    assert_response :not_found
  end

  test "marks the language, the current verse and the live region for assistive tech" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "html[lang=en]"
    assert_select ".tick[aria-current=true]", 1
    assert_select ".tick[aria-current=true]", "25"
    assert_select ".now[aria-live=polite]"
    assert_select ".near[aria-hidden=true]", 2
    assert_select ".panel-handle[aria-expanded=false]"
  end

  test "the reading page has an autosaving note editor for the current verse" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "turbo-frame#note_editor form[action=?]", unit_note_path(verse(25))
  end

  test "the page title names the chapter" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "title", "Isaiah 40 · Study Carrel"
  end

  test "the nav shows breadcrumbs from the library down to the chapter" do
    get reading_path("isaiah-kjv", 40, 25)
    labels = css_select(".crumbs li").map { |i| i.text.strip }.reject { |t| t == "…" }
    assert_equal "Library", labels.first
    assert_equal "Isaiah 40", labels.last
    assert_includes labels, "Old Testament"
    assert_equal 1, labels.count { |t| t.start_with?("Isaiah") }
    assert_select ".crumbs li:last-child a[aria-current=page]", "Isaiah 40"
  end

  test "requires sign in" do
    delete session_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_session_path
  end
end
