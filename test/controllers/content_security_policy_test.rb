require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  setup { load_isaiah }

  test "pages send a policy that allows only this site's scripts" do
    get root_path
    policy = response.headers["Content-Security-Policy"]
    assert_match "default-src 'self'", policy
    assert_match "object-src 'none'", policy
    assert_match "frame-ancestors 'none'", policy
  end

  test "the inline scripts carry the policy's nonce" do
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    get library_path
    nonce = response.headers["Content-Security-Policy"][/script-src [^;]*'nonce-([^']+)'/, 1]
    assert nonce.present?
    scripts = css_select("script:not([src])")
    assert_operator scripts.size, :>=, 2 # theme and importmap
    scripts.each { |script| assert_equal nonce, script["nonce"] }
  end
end
