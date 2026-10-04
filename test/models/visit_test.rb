require "test_helper"

class VisitTest < ActiveSupport::TestCase
  setup do
    load_isaiah
    @user = users(:one)
  end

  def places = @user.visits.recent.map { |v| v.unit.number }

  test "lists places most recent first" do
    [ 3, 20, 10 ].each { |n| Visit.record(@user, verse(n)) }
    assert_equal [ 10, 20, 3 ], places
  end

  test "revisiting a place moves it to the top rather than repeating it" do
    [ 3, 20, 10, 3 ].each { |n| Visit.record(@user, verse(n)) }
    assert_equal [ 3, 10, 20 ], places
  end

  test "reading on to the next verse moves the latest entry along" do
    [ 3, 20, 21, 22, 21 ].each { |n| Visit.record(@user, verse(n)) }
    assert_equal [ 21, 3 ], places
  end

  test "keeps only the most recent places" do
    units = Unit.order(:id).each_slice(2).map(&:first).first(Visit::LIMIT + 5)
    units.each { |u| Visit.record(@user, u) }
    assert_equal Visit::LIMIT, @user.visits.count
    assert_equal units.last, @user.visits.recent.first.unit
    assert_not_includes @user.visits.map(&:unit), units.first
  end

  test "is per user" do
    Visit.record(@user, verse(3))
    assert_empty users(:two).visits
  end
end
