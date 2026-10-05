require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "What does it mean to be holy?")
    sign_in_as users(:one)
  end

  test "defaults to the first verse" do
    get reading_path("isaiah-kjv", 40)
    assert_response :success
    assert_select ".now .ref", "Isaiah 40:1"
    assert_select ".step-of", "1 of 31"
    assert_select ".unit-grid .cell", 31
    assert_select ".cell.current", "1"
  end

  test "the URL selects the verse, and the arrows name the verses either side" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".now", /To whom then will ye liken me/
    assert_select ".now", text: /Have ye not known/, count: 0
    assert_select ".step-of", "25 of 31"
    assert_select "button.step[title=?]", "Verse 24"
    assert_select "button.step[title=?]", "Verse 26"
    assert_select ".cell.current", "25"
  end

  test "at a chapter's edge the arrows name the neighboring chapter" do
    get reading_path("isaiah-kjv", 40, 1)
    assert_select "button.step[title=?]", "Isaiah 39"
    get reading_path("isaiah-kjv", 40, 31)
    assert_select "button.step[title=?]", "Isaiah 41"
  end

  test "the phone sheet's handle shows the start of the note, or invites one" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".panel-handle .preview.empty", "Write a note"

    @focus.notes.create!(unit: verse(25), content: "<p>The holy as the <em>incomparable</em>.</p>")
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".panel-handle .preview:not(.empty)", "The holy as the incomparable."
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
    assert_select ".cell[aria-current=true]", 1
    assert_select ".cell[aria-current=true]", "25"
    assert_select ".now[aria-live=polite]"
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

  test "the rail shows where you are, from the library down to the chapter, with the chapters either side" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".crumbs", 0
    labels = css_select("#rail-library .trail li").map { |i| i.text.strip }
    assert_equal "Library", labels.first
    assert_equal "Isaiah 40", labels.last
    assert_includes labels, "Old Testament"
    assert_equal 1, labels.count { |t| t.start_with?("Isaiah") }
    assert_select "#rail-library .trail li:last-child a[aria-current=page]", "Isaiah 40"
    assert_select "#rail-library .trail-sides a[href=?]", reading_path("isaiah-kjv", 39), text: /Isaiah 39/
    assert_select "#rail-library .trail-sides a[href=?]", reading_path("isaiah-kjv", 41), text: /Isaiah 41/
  end

  test "the rail has recent places, search, kept and the menu" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select ".rail .history-btn[aria-label=?]", "Recent places"
    assert_select ".rail a.rail-btn[href=?]", search_path
    assert_select ".rail a.rail-btn[href=?]", kept_path
    assert_select ".rail #nav-menu a.menu-item[href=?]", foci_path
    assert_select ".rail #nav-menu", text: /Continue reading/, count: 0
  end

  test "requires sign in" do
    delete session_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_session_path
  end
end
