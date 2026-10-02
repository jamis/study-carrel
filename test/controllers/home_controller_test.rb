require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "shows the study page when signed in" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
    assert_select ".focus-title"
  end
end
