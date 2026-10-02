require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "the manifest is public and describes an installable app" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    manifest = JSON.parse(response.body)

    assert_equal "Study", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
    assert_includes manifest["icons"].map { |i| i["sizes"] }, "192x192"
    assert_includes manifest["icons"].map { |i| i["sizes"] }, "512x512"
    assert_includes manifest["icons"].map { |i| i["purpose"] }, "maskable"
    manifest["icons"].each { |i| assert File.exist?(Rails.root.join("public", i["src"].delete_prefix("/"))), i["src"] }
  end

  test "the service worker is public" do
    get pwa_service_worker_path(format: :js)
    assert_response :success
    assert_match "fetch", response.body
  end

  test "pages link the manifest and theme colors" do
    get new_session_path
    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
    assert_select "meta[name=theme-color]", 2
  end
end
