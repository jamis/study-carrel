require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "signing in returns to the page that asked for it" do
    get kept_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to kept_url
  end

  test "an autosave or a frame that asked for sign-in isn't returned to" do
    put unit_note_path(1), params: { note: { content: "x" } }, as: :turbo_stream
    get unit_note_path(1), headers: { "Turbo-Frame" => "note_editor" }

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_url
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "signing out ends the user's sessions on every device, and nobody else's" do
    other_device = @user.sessions.create!
    other_user = User.where.not(id: @user.id).take.sessions.create!
    sign_in_as(@user)

    delete session_path

    assert_empty @user.sessions.reload
    assert_not Session.exists?(other_device.id)
    assert Session.exists?(other_user.id)
  end

  test "the next person to sign in on the browser doesn't inherit the last one's places searched" do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    post session_path, params: { email_address: @user.email_address, password: "password" }
    get search_path(q: "light", collection: "bible")
    get kept_path
    assert_select ".rail-search[href=?]", search_path(collection: "bible")

    delete session_path
    post session_path, params: { email_address: users(:two).email_address, password: "password" }
    get kept_path
    assert_select ".rail-search[href=?]", search_path
  end

  test "signing in starts a fresh session, keeping only the page that asked for it" do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    sign_in_as(@user)
    get search_path(q: "light", collection: "bible")
    cookies.delete("session_id")

    get kept_path
    assert_redirected_to new_session_path
    post session_path, params: { email_address: users(:two).email_address, password: "password" }
    assert_redirected_to kept_url
    follow_redirect!
    assert_select ".rail-search[href=?]", search_path
  end

  test "a session older than 30 days no longer signs you in" do
    sign_in_as(@user)
    Current.session.update!(created_at: 31.days.ago)

    get kept_path
    assert_redirected_to new_session_path
  end

  test "a session just under 30 days old still works" do
    sign_in_as(@user)
    Current.session.update!(created_at: 29.days.ago)

    get kept_path
    assert_response :success
  end
end
