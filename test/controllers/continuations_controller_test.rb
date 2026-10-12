require "test_helper"

class ContinuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
  end

  test "sends a focus with no reading yet to the library" do
    users(:one).foci.start!(title: "Holy")
    get continue_path
    assert_redirected_to library_path
  end

  test "resumes the last verse read under the focus" do
    focus = users(:one).foci.start!(title: "Holy")
    unit = Unit.joins(:section).order("sections.number", :number).first
    focus.update!(last_unit: unit)
    get continue_path
    assert_redirected_to reading_path("isaiah-kjv", unit.section.number, unit.number)
  end

  test "with no focus, sends you to make one" do
    get continue_path
    assert_redirected_to new_focus_path
  end
end
