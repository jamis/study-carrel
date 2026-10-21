require "test_helper"

class UnitFociControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @unit = verse(25)
    sign_in_as users(:one)
  end

  def start(*titles) = titles.map { users(:one).foci.start!(title: it) }

  test "the other focuses, those noted on the passage first, then most recently current first" do
    oldest, noted, recent = start("Oldest", "Noted", "Recent")
    noted.notes.create!(unit: @unit, content: "x")
    recent.notes.create!(unit: verse(3), content: "y")
    start("Current")
    get unit_foci_path(@unit), headers: { "Turbo-Frame" => "other_foci" }
    assert_response :success
    assert_select ".pick-title", count: 3
    assert_equal %w[Noted Recent Oldest], css_select(".pick-title").map(&:text)
    assert_select "a.pick[href=?][data-turbo-frame=note_editor]", focus_unit_note_path(oldest, @unit)
    assert_select ".pick-noted", count: 1
    assert_no_match "Current", css_select(".pick-list").text
    assert_select ".pick-filter", false
    assert_select ".pick-all", false
  end

  test "a long list shows five until asked for all, with a filter" do
    start(*(1..9).map { "Focus #{it}" }, "Current")
    get unit_foci_path(@unit)
    assert_select ".pick-list li", count: 9
    assert_select ".pick-list li:not([hidden])", count: 5
    assert_select ".pick-all", "All 9 focuses…"
    assert_select "input.pick-filter"
  end

  test "with no other focus, nothing" do
    start("Current")
    get unit_foci_path(@unit)
    assert_select ".pick-list", false
  end

  test "another user's focuses are never listed" do
    users(:two).foci.start!(title: "Theirs")
    users(:two).foci.start!(title: "Theirs now")
    start("Mine", "Current")
    get unit_foci_path(@unit)
    assert_equal %w[Mine], css_select(".pick-title").map(&:text)
  end
end
