require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "sessions expire 30 days after sign-in" do
    user = User.take
    fresh = user.sessions.create!
    old = user.sessions.create!(created_at: 31.days.ago)

    assert_equal [ fresh ], Session.active.where(id: [ fresh, old ]).to_a
    assert_equal [ old ], Session.expired.where(id: [ fresh, old ]).to_a
  end
end
