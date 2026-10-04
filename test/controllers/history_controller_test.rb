require "test_helper"

class HistoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @user = users(:one)
    @user.foci.start!(title: "Holy")
    sign_in_as @user
  end

  test "lists earlier places, newest first, leaving out the current one" do
    [ 3, 20, 10 ].each { |n| Visit.record(@user, verse(n)) }
    get history_path
    assert_response :success
    assert_select "a.hist-item", 2
    assert_select "a.hist-item:first-of-type .hist-ref", /Isaiah 40:20/
    assert_select "a.hist-item[href=?]", reading_path("isaiah-kjv", 40, 3)
    assert_select ".hist-item", text: /Isaiah 40:10/, count: 0
  end

  test "is empty until there is somewhere to go back to" do
    Visit.record(@user, verse(3))
    get history_path
    assert_select ".hist-empty"
  end

  test "marks places that have a note in the current focus" do
    focus = @user.foci.current_one
    focus.notes.create!(unit: verse(3), content: "mine")
    [ 3, 20 ].each { |n| Visit.record(@user, verse(n)) }
    get history_path
    assert_select ".hist-note", 1
  end

  test "survives starting a new focus" do
    [ 3, 20 ].each { |n| Visit.record(@user, verse(n)) }
    @user.foci.start!(title: "Next")
    get history_path
    assert_select "a.hist-item", 1
  end

  test "never shows another user's places" do
    Visit.record(users(:two), verse(3))
    Visit.record(users(:two), verse(20))
    get history_path
    assert_select ".hist-item", 0
  end

  test "the reading page has the button" do
    get reading_path("isaiah-kjv", 40)
    assert_select "button.history-btn"
  end
end
