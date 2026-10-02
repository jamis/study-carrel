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

  test "the note composer has a place to report a failed save" do
    get reading_path("isaiah-kjv", 40)
    assert_select ".composer [data-composer-target=error][role=alert][hidden]"
  end

  test "the page title names the chapter" do
    get reading_path("isaiah-kjv", 40, 25)
    assert_select "title", "Isaiah 40 · Study Carrel"
  end

  test "requires sign in" do
    delete session_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_session_path
  end
end
