require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup { load_isaiah }

  test "shows the landing page to visitors" do
    get root_path
    assert_response :success
    assert_select "h1", "Study Carrel"
    assert_select "a[href=?]", new_session_path
    assert_select "a[href^=mailto]", false
  end

  test "redirects to the first section when signed in" do
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    get root_path
    assert_redirected_to reading_path("isaiah-kjv", 1)
  end

  test "explains when no texts are loaded" do
    Section.destroy_all
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    get root_path
    assert_response :success
    assert_select "h2", "No texts yet"
  end
end
