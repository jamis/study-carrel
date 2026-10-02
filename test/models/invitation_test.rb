require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup { @admin = users(:one) }

  def invite(**attrs) = @admin.invitations.create!(**attrs)

  test "a new invitation has a token, stored only as a digest, and expires in a week" do
    invitation = invite(label: "Sam")
    assert invitation.token.present?
    assert_equal Invitation.digest(invitation.token), invitation.token_digest
    assert_not_equal invitation.token, invitation.token_digest
    assert_nil Invitation.find(invitation.id).token
    assert_in_delta 7.days.from_now, invitation.expires_at, 5.seconds
    assert_equal :pending, invitation.status
  end

  test "tokens are unique" do
    assert_equal 2, 2.times.map { invite.token }.uniq.size
  end

  test "only a pending invitation can be found by its token" do
    invitation = invite
    assert_equal invitation, Invitation.find_redeemable(invitation.token)
    assert_nil Invitation.find_redeemable("nope")
    assert_nil Invitation.find_redeemable(nil)

    invitation.update!(expires_at: 1.minute.ago)
    assert_equal :expired, invitation.status
    assert_nil Invitation.find_redeemable(invitation.token)
  end

  test "revoking makes it unusable" do
    invitation = invite
    assert invitation.revoke!
    assert_equal :revoked, invitation.status
    assert_nil Invitation.find_redeemable(invitation.token)
    assert_not invitation.revoke!, "a used or revoked invitation can't be revoked again"
  end

  test "redeeming creates the user and uses up the invitation" do
    invitation = invite
    user = invitation.redeem(email_address: "New@Example.com", password: "long enough", password_confirmation: "long enough")

    assert user.persisted?
    assert_equal "new@example.com", user.email_address
    assert_not user.admin?
    invitation.reload
    assert_equal :used, invitation.status
    assert_equal user, invitation.redeemed_by
    assert_nil Invitation.find_redeemable(invitation.token)
  end

  test "an invalid sign-up leaves the invitation unused" do
    invitation = invite
    user = invitation.redeem(email_address: "new@example.com", password: "short", password_confirmation: "short")
    assert_not user.persisted?
    assert user.errors[:password].any?
    assert_equal :pending, invitation.reload.status

    user = invitation.redeem(email_address: "one@example.com", password: "long enough", password_confirmation: "long enough")
    assert_not user.persisted?, "an email address that's taken can't sign up"
    assert_equal :pending, invitation.reload.status

    user = invitation.redeem(email_address: "new@example.com", password: "long enough", password_confirmation: "different")
    assert_not user.persisted?
    assert_equal :pending, invitation.reload.status
  end

  test "a link that was already used can't be used again, even by a stale copy" do
    invitation = invite
    stale = Invitation.find(invitation.id)
    assert invitation.redeem(email_address: "a@example.com", password: "long enough", password_confirmation: "long enough").persisted?

    second = stale.redeem(email_address: "b@example.com", password: "long enough", password_confirmation: "long enough")
    assert_not second.persisted?
    assert_nil User.find_by(email_address: "b@example.com")
  end
end
