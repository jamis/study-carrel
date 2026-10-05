require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "starting a focus archives only this user's current focus" do
    mine = users(:one).foci.start!(title: "Holy")
    theirs = users(:two).foci.start!(title: "Theirs")

    newer = users(:one).foci.start!(title: "Next")

    assert mine.reload.archived?
    assert_not theirs.reload.archived?
    assert_equal newer, users(:one).foci.current_one
    assert_equal theirs, users(:two).foci.current_one
  end

  test "start! and current_one are not callable on Focus itself" do
    assert_not Focus.respond_to?(:start!)
    assert_not Focus.respond_to?(:current_one)
  end
end
