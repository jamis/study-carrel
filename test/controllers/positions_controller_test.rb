require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "saves the current verse on the focus" do
    unit = verse(25)
    patch position_path, params: { unit_id: unit.id }, as: :json
    assert_response :no_content
    assert_equal unit, @focus.reload.last_unit
  end

  test "the app reopens at the saved verse" do
    @focus.update!(last_unit: verse(25))
    get root_path
    assert_redirected_to reading_path("isaiah-kjv", 40, 25)

    get reading_path("isaiah-kjv", 40)
    assert_select ".tick.current", "25"
  end

  test "an explicit verse in the URL wins over the saved one" do
    @focus.update!(last_unit: verse(25))
    get reading_path("isaiah-kjv", 40, 3)
    assert_select ".tick.current", "3"
  end

  test "each focus remembers its own place" do
    @focus.update!(last_unit: verse(25))
    users(:one).foci.start!(title: "Next")
    get root_path
    assert_redirected_to library_path
  end

  test "the page tells the controller where to report" do
    get reading_path("isaiah-kjv", 40, 7)
    assert_select "[data-lectio-position-url-value=?]", position_path
  end
end
