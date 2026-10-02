require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    Focus.start!(title: "What does it mean to be holy?")
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

  test "requires sign in" do
    delete session_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_session_path
  end
end
