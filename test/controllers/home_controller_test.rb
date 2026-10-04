require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup { load_isaiah }

  test "shows the landing page to visitors" do
    get root_path
    assert_response :success
    assert_select "h1", "Study Carrel"
    assert_select "a[href=?]", new_session_path
    assert_select "a[href^=mailto]", false
  end

  test "the landing page lists the library's collections and works" do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Walden\nauthor: Henry David Thoreau\ncollection: prose\nposition: 1\n\nsection: 1\n1. p\n").load
    get root_path
    assert_select ".works h3", "Prose"
    assert_select ".works li", text: "Henry David Thoreau, Walden"
    assert_select ".works li", text: "Bible" # a child collection is one item
    assert_select ".works li", text: "Old Testament", count: 0
  end

  test "sends a focus with no reading yet to the library" do
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
    get root_path
    assert_redirected_to library_path
  end

  test "resumes the last verse read under the focus" do
    focus = users(:one).foci.start!(title: "Holy")
    unit = Unit.joins(:section).order("sections.number", :number).first
    focus.update!(last_unit: unit)
    sign_in_as users(:one)
    get root_path
    assert_redirected_to reading_path("isaiah-kjv", unit.section.number, unit.number)
  end
end
