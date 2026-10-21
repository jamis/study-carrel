require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "starting a focus makes it current, leaving the old one among the others and another user's alone" do
    mine = users(:one).foci.start!(title: "Holy")
    theirs = users(:two).foci.start!(title: "Theirs")

    newer = users(:one).foci.start!(title: "Next")

    assert_not mine.reload.archived?
    assert_equal newer, users(:one).foci.current_one
    assert_equal [ mine ], users(:one).foci.others.to_a
    assert_equal theirs, users(:two).foci.current_one
  end

  test "the focus most recently made current is current; the others are most recently current first" do
    first = users(:one).foci.start!(title: "First")
    second = users(:one).foci.start!(title: "Second")
    third = users(:one).foci.start!(title: "Third")

    first.make_current!
    assert_equal first, users(:one).foci.current_one
    assert_equal [ third, second ], users(:one).foci.others.to_a
  end

  test "archiving the current focus leaves none current; unarchived, it's current again only if none was made current since" do
    old = users(:one).foci.start!(title: "Old")
    holy = users(:one).foci.start!(title: "Holy")

    holy.archive!
    assert_nil users(:one).foci.current_one
    assert_equal [ old ], users(:one).foci.others.to_a
    holy.unarchive!
    assert_equal holy, users(:one).foci.current_one

    holy.archive!
    old.make_current!
    holy.unarchive!
    assert_equal old, users(:one).foci.current_one
    assert_equal [ holy ], users(:one).foci.others.to_a
  end

  test "archived foci aren't among the others" do
    users(:one).foci.start!(title: "Put away").archive!
    users(:one).foci.start!(title: "Holy")
    assert_empty users(:one).foci.others
    assert_equal [ "Put away" ], users(:one).foci.archived.map(&:title)
  end

  test "start! and current_one are not callable on Focus itself" do
    assert_not Focus.respond_to?(:start!)
    assert_not Focus.respond_to?(:current_one)
  end
end
