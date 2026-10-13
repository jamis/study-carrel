require "test_helper"

class ShelvesControllerTest < ActionDispatch::IntegrationTest
  setup do
    TextLoader.load_collections(Rails.root.join("db/texts/collections.yml"))
    TextLoader.new("work: Genesis\nedition: KJV\ncollection: old-testament\nposition: 1\n\nsection: 1\n1. Let there be light.\n").load
    TextLoader.new("work: Walden\nauthor: Henry David Thoreau\nauthor_short: Thoreau\nunit: paragraph\ncollection: prose\nposition: 1\n\nsection: 1\nlabel: Economy\n1. The light which puts out our eyes.\n").load
    @user = users(:one)
    @user.foci.start!(title: "Holy")
    sign_in_as @user
    @genesis, @walden = Work.find_by!(slug: "genesis-kjv"), Work.find_by!(slug: "walden")
    @bible = Collection.find_by!(slug: "bible")
  end

  test "the editor makes a shelf from what's ticked" do
    get new_shelf_path
    assert_select "input[type=checkbox][name='items[]'][value=?]", "collection-#{@bible.id}"
    assert_select "input[type=checkbox][value=?]", "work-#{@walden.id}"

    post shelves_path, params: { shelf: { name: "Light", description: "Where light is" },
                                 items: [ "", "collection-#{@bible.id}", "work-#{@genesis.id}", "work-#{@walden.id}" ] }
    shelf = @user.shelves.sole
    assert_redirected_to shelf_path(shelf)
    assert_equal [ @bible, @walden ], shelf.members, "Genesis is already there through the Bible"

    follow_redirect!
    assert_select ".page-title", "Light"
    assert_select ".shelf-desc", "Where light is"
    assert_select ".list-row-title a[href=?]", collection_path(@bible)
    assert_select "a.work-link[href=?]", work_path(@walden)
    assert_select ".shelf-lede", /2 works in all/
    assert_select "input[type=search][placeholder=?]", "Find words in Light"
  end

  test "a shelf needs a name" do
    post shelves_path, params: { shelf: { name: " " } }
    assert_response :unprocessable_content
    assert_equal 0, Shelf.count
  end

  test "editing shows what's on it, greys what's on it through a collection, and saves what's ticked" do
    shelf = @user.shelves.create!(name: "Light")
    shelf.replace!([ @bible ])

    get edit_shelf_path(shelf)
    assert_select "input[value=?][checked]", "collection-#{@bible.id}"
    assert_select "input[value=?][checked][disabled]", "work-#{@genesis.id}"

    patch shelf_path(shelf), params: { shelf: { name: "Dark" }, items: [ "", "work-#{@walden.id}" ] }
    assert_redirected_to shelf_path(shelf)
    assert_equal "Dark", shelf.reload.name
    assert_equal [ @walden ], shelf.members
  end

  test "deleting a shelf goes back to the library" do
    shelf = @user.shelves.create!(name: "Light")
    shelf.replace!([ @walden ])
    delete shelf_path(shelf)
    assert_redirected_to library_path
    assert_equal 0, Shelf.count
    assert Work.exists?(@walden.id)
  end

  test "the library lists the shelves, and its Random offers them" do
    shelf = @user.shelves.create!(name: "Light")
    shelf.replace!([ @bible, @walden ])
    get library_path
    assert_select ".list-row-title", "Your shelves"
    assert_select "a[href=?]", shelf_path(shelf), text: "Light"
    assert_select ".shelf-holds", "Bible · Walden"
    assert_select ".menu-sub a[href=?]", random_shelf_path(shelf), text: "Random in Light"
  end

  test "a work's page offers Random in the shelves holding it, and its picker shows where it stands" do
    holding = @user.shelves.create!(name: "Scripture")
    holding.replace!([ @bible ])
    other = @user.shelves.create!(name: "Woods")

    get work_path(@genesis)
    assert_select ".menu-sub a[href=?]", random_shelf_path(holding)
    assert_select ".menu-sub a[href=?]", random_shelf_path(other), count: 0
    assert_select "#shelf-picker .pop-row.through", text: /Scripture\s*On it through Bible/
    assert_select "#shelf-picker form[action=?]", shelf_item_path(other, key: "work-#{@genesis.id}")
  end

  test "Random and search reach a shelf's works" do
    shelf = @user.shelves.create!(name: "Light")
    shelf.replace!([ @walden ])
    get random_shelf_path(shelf)
    assert_redirected_to reading_path("walden", 1, 1)

    get search_path(q: "light", shelf: shelf.slug)
    assert_select ".search-summary", /1 passage/
    assert_select ".search-scopes .chip.current", "Light"
  end

  test "ticking a shelf in the picker puts the thing on it, and unticking takes it off" do
    shelf = @user.shelves.create!(name: "Light")
    shelf.replace!([ @genesis ])

    post shelf_item_path(shelf, key: "collection-#{@bible.id}"), as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=replace][target=shelf-picker]"
    assert_equal [ @bible ], shelf.members, "the Bible takes in Genesis"

    delete shelf_item_path(shelf, key: "collection-#{@bible.id}"), as: :turbo_stream
    assert_empty shelf.members
  end

  test "a new shelf from the picker gets the thing it was opened on" do
    post shelves_path(key: "work-#{@walden.id}"), params: { shelf: { name: "Woods" } }, as: :turbo_stream
    assert_select "turbo-stream[target=shelf-picker]"
    assert_equal [ @walden ], @user.shelves.sole.members
  end
end
