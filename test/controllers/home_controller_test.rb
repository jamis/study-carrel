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

  test "sends a focus with no reading yet to the library" do
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    get root_path
    assert_redirected_to library_path
  end

  test "resumes the last verse read under the focus" do
    focus = users(:one).foci.start!(title: "Holy")
    unit = Unit.joins(:section).order("sections.number", :number).first
    focus.update!(last_unit: unit)
    sign_in_as users(:one)
    get root_path
    assert_redirected_to reading_path("isaiah-kjv", unit.section.number, unit.number)
  end
end
