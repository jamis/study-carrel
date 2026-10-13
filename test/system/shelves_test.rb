require "application_system_test_case"

class ShelvesTest < ApplicationSystemTestCase
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n").load
    TextLoader.new("work: Exodus\nedition: KJV\ncollection: old-testament\nposition: 2\n\nsection: 1\n1. Moses.\n").load
    TextLoader.new("work: Walden\nauthor: Henry David Thoreau\nauthor_short: Thoreau\nunit: paragraph\ncollection: prose\nposition: 1\n\nsection: 1\nlabel: Economy\n1. The light which puts out our eyes.\n").load
    users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "make a shelf in the editor: a ticked collection brings what's under it" do
    visit library_path
    click_on "New shelf"
    fill_in "Name this shelf", with: "Light"

    find(".tree-toggle[aria-label='Show what’s in Bible']").click
    find(".tree-toggle[aria-label='Show what’s in Old Testament']").click
    check "Genesis"
    assert_selector ".held", text: "Genesis"
    assert_selector ".tree-row.some .tree-meta", text: "1 on the shelf", count: 3

    check "Bible"
    assert_selector ".tree-row.through .tree-meta", text: "through Bible", minimum: 3
    assert_field "Genesis", checked: true, disabled: true
    assert_no_selector ".held", text: "Genesis"

    fill_in "Find a work, collection or author", with: "thoreau"
    assert_selector ".tree-name", text: "Walden"
    assert_no_selector ".tree-name", text: "Bible"
    check "Walden"
    fill_in "Find a work, collection or author", with: ""
    assert_selector ".tree-name", text: "Bible"

    click_on "Make the shelf"
    assert_selector ".page-title", text: "Light"
    assert_selector ".list-row-title", text: "Bible"
    assert_selector ".work-link", text: "Walden"

    click_on "Edit shelf"
    find(".held", text: "Bible").click_on("×")
    assert_field "Genesis", checked: false, disabled: false, visible: :all # folded away inside the Bible
    click_on "Save"
    assert_no_selector ".list-row-title", text: "Bible"
  end

  test "put a work on a shelf from its page, and on a new one" do
    light = users(:one).shelves.create!(name: "Light")
    visit work_path("walden")
    click_on "Put on a shelf…"
    check "Light"
    assert_selector "#shelf-pick-#{light.id} input[name=_method][value=delete]", visible: false # drawn again, now to take it off
    assert_equal [ "Walden" ], users(:one).shelves.sole.members.map(&:title)

    click_on "New shelf…"
    fill_in "Name the shelf", with: "Woods"
    click_on "Add"
    assert_field "Woods", checked: true
    assert_equal [ "Walden" ], users(:one).shelves.find_by!(name: "Woods").members.map(&:title)

    uncheck "Light"
    assert_no_selector "#shelf-pick-#{light.id} input[name=_method]", visible: false
    assert_empty users(:one).shelves.find_by!(name: "Light").items
  end
end
