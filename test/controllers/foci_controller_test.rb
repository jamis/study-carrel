require "test_helper"

class FociControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_file(Rails.root.join("db/texts/isaiah-kjv.txt"))
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
