require "test_helper"

class InvitationsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(admin: true)
    @invitation = @admin.invitations.create!(label: "Sam")
    @token = @invitation.token
  end

  def join_params(**over) = { user: { email_address: "sam@example.com", password: "long enough", password_confirmation: "long enough" }.merge(over) }
  def without_nonces(html) = html.gsub(/(nonce|name="csp-nonce" content)="[^"]*"/, '\1=""') # the CSP nonce changes with every request

  test "the join page is open to anyone holding a valid link" do
    get join_path(token: @token)
    assert_response :success
    assert_select "form[action=?]", join_path(token: @token)
    assert_select "input[type=password]", 2
  end

  test "signing up creates a regular user, signs them in, and uses up the link" do
    assert_difference "User.count", 1 do
      post join_path(token: @token), params: join_params
    end
    assert_redirected_to root_path
    sam = User.find_by!(email_address: "sam@example.com")
    assert_not sam.admin?
    follow_redirect!
    assert_redirected_to new_focus_path   # signed in, with nothing begun yet

    sign_out
    get join_path(token: @token)
    assert_response :not_found
    assert_select ".signin-alert", /isn't valid/
  end

  test "a bad password or mismatch re-renders the form and keeps the link good" do
    assert_no_difference "User.count" do
      post join_path(token: @token), params: join_params(password: "short", password_confirmation: "short")
    end
    assert_response :unprocessable_entity
    assert_select ".signin-alert", /too short/
    assert_equal :pending, @invitation.reload.status

    post join_path(token: @token), params: join_params(password_confirmation: "nope nope nope")
    assert_response :unprocessable_entity
    assert_equal :pending, @invitation.reload.status
  end

  test "unknown, expired and revoked links all look the same" do
    get join_path(token: "bogus")
    assert_response :not_found
    expected = without_nonces(response.body)

    @invitation.update!(expires_at: 1.hour.ago)
    get join_path(token: @token)
    assert_response :not_found
    assert_equal expected, without_nonces(response.body)

    other = @admin.invitations.create!
    other.revoke!
    get join_path(token: other.token)
    assert_response :not_found
    post join_path(token: other.token), params: join_params
    assert_response :not_found
    assert_not User.exists?(email_address: "sam@example.com")
  end

  test "a signed-in user is sent home instead of signing up again" do
    sign_in_as users(:two)
    get join_path(token: @token)
    assert_redirected_to root_path
    assert_equal :pending, @invitation.reload.status
  end

  test "an admin sees the invitations page and can create and revoke invitations" do
    sign_in_as @admin
    get admin_invitations_path
    assert_response :success
    assert_select ".list-row-title", "Sam"

    assert_difference "Invitation.count", 1 do
      post admin_invitations_path, params: { label: "Ruth" }
    end
    assert_redirected_to admin_invitations_path
    follow_redirect!
    link = css_select("input.invite-link").first["value"]
    assert_match %r{/join/[\w-]{20,}\z}, link
    token = link[%r{/join/(.+)\z}, 1]
    assert Invitation.find_redeemable(token), "the link shown works"
    assert_select ".page-sub", /New invitation for Ruth/

    get admin_invitations_path
    assert_select "input.invite-link", 0   # shown once

    assert_select "form[action=?]", revoke_admin_invitation_path(@invitation)
    patch revoke_admin_invitation_path(@invitation)
    assert_equal :revoked, @invitation.reload.status
  end

  test "the invitations link only appears for admins" do
    load_isaiah
    @admin.foci.start!(title: "Holy")
    sign_in_as @admin
    get reading_path("isaiah-kjv", 40, 1)
    assert_select "a[href=?]", admin_invitations_path

    users(:two).foci.start!(title: "Holy")
    sign_in_as users(:two)
    get reading_path("isaiah-kjv", 40, 1)
    assert_select "a[href=?]", admin_invitations_path, 0
  end

  test "non-admins and visitors can't reach the admin pages" do
    get admin_invitations_path
    assert_redirected_to new_session_path

    sign_in_as users(:two)
    get admin_invitations_path
    assert_response :not_found
    assert_no_difference "Invitation.count" do
      post admin_invitations_path, params: { label: "Sneaky" }
    end
    assert_response :not_found
    patch revoke_admin_invitation_path(@invitation)
    assert_response :not_found
    assert_equal :pending, @invitation.reload.status
  end
end
