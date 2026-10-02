require "test_helper"

class FociControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
  end

  test "first run: no focus sends you to the new-focus form" do
    get root_path
    assert_redirected_to new_focus_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_focus_path
    get new_focus_path
    assert_response :success
  end

  test "creating a focus shows it in the band" do
    post foci_path, params: { focus: { title: "What does it mean to be holy?", description: "Set apart or good?" } }
    assert_redirected_to root_path
    follow_redirect!
    follow_redirect!
    assert_select ".focus-title", "What does it mean to be holy?"
    assert_select ".focus-body", /Set apart or good/
    assert_select ".pfocus", "What does it mean to be holy?"
  end

  test "title is required" do
    post foci_path, params: { focus: { title: "" } }
    assert_response :unprocessable_entity
    assert_equal 0, Focus.count
  end

  test "a new focus archives the previous one" do
    Focus.start!(title: "Old")
    post foci_path, params: { focus: { title: "New" } }
    assert_equal "New", Focus.current_one.title
    assert_equal 1, Focus.current.count
    assert_equal 2, Focus.count
  end
end

class FociManagementTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
    @focus = Focus.start!(title: "Holy", description: "Set apart?")
  end

  test "edit updates the focus" do
    get edit_focus_path(@focus)
    assert_response :success
    patch focus_path(@focus), params: { focus: { title: "Holy, revisited" } }
    assert_redirected_to root_path
    assert_equal "Holy, revisited", @focus.reload.title
  end

  test "blank title on update is rejected" do
    patch focus_path(@focus), params: { focus: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "past foci list shows archived foci and can restore one" do
    @focus.archive!
    other = Focus.start!(title: "Light")
    get foci_path
    assert_select ".focus-row-title", "Light"
    assert_select ".focus-row-title", "Holy"

    patch restore_focus_path(@focus)
    assert_equal "Holy", Focus.current_one.title
    assert other.reload.archived?
    assert_equal 1, Focus.current.count
  end

  test "the band offers edit, new focus and all foci" do
    get reading_path("isaiah-kjv", 40)
    assert_select ".focus-actions a[href=?]", edit_focus_path(@focus)
    assert_select ".focus-actions a[href=?]", new_focus_path, text: "New focus"
    assert_select ".focus-actions a[href=?]", foci_path
  end
end
