require "test_helper"

class RandomReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. a\n2. b\n").load
    TextLoader.new("work: Exodus\nedition: KJV\ncollection: old-testament\nposition: 2\n\nsection: 1\n1. c\n").load
    TextLoader.new("work: Walden\nunit: paragraph\ncollection: prose\nposition: 200\n\nsection: 1\nlabel: Economy\n1. p\n").load
    Focus.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "a work yields only its own units" do
    10.times do
      get random_work_path("exodus-kjv")
      assert_redirected_to reading_path("exodus-kjv", 1, 1)
    end
  end

  test "a collection stays inside the collection and reaches every book" do
    seen = 40.times.map { get(random_collection_path("old-testament")); response.location[%r{/read/([^/]+)}, 1] }.uniq
    assert_equal %w[exodus-kjv genesis-kjv], seen.sort
  end

  test "the library picks a collection first, so a small one is not swamped" do
    slugs = 60.times.map { get(random_path); response.location[%r{/read/([^/]+)}, 1] }
    assert_includes slugs, "walden"
  end

  test "an unknown or empty scope is not found" do
    get random_work_path("nope")
    assert_response :not_found
    get random_collection_path("poetry")
    assert_response :not_found
  end

  test "landing on the unit moves the reading position" do
    get random_work_path("walden")
    follow_redirect!
    assert_response :success
    assert_select "[data-lectio-position-url-value]"
  end
end
