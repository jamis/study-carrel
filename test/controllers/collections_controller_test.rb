require "test_helper"

# A user's own collections: made empty from Your Texts, filled by adding texts into them, and deleted with their texts.
class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.foci.start!(title: "What is rest?")
    sign_in_as @user
  end

  def add_text(title, collection) = UserText.new(title:, source: "Words about #{title}.", collection_id: collection&.id).publish!(@user)

  test "a new collection starts empty, under Your Texts" do
    get new_collection_path
    assert_response :success
    post collections_path, params: { collection: { name: "  Pearl of  Great Price ", description: "The 1913 edition." } }

    pearl = @user.collections.sole
    assert_equal "Pearl of Great Price", pearl.name
    assert_redirected_to collection_path(pearl)
    follow_redirect!
    assert_select ".page-trail a", text: "Your Texts"
    assert_select ".page-empty", /Nothing in it yet/
    assert_select "a[href=?]", new_text_path(collection: pearl.slug)
    assert_select "a[href=?]", delete_collection_path(pearl)

    get texts_path
    assert_select ".list-row-title a[href=?]", collection_path(pearl), text: "Pearl of Great Price"
    assert_select ".list-row-meta", /No texts yet/
    get library_path
    assert_select ".list-row-meta", /1 collection/
  end

  test "a collection can be one work in parts, its texts counted as books and listed like a work" do
    post collections_path, params: { collection: { name: "Pearl", description: "", single_work: "1" } }
    post collections_path, params: { collection: { name: "Journals", description: "", single_work: "0" } }
    pearl, journals = @user.collections.find_by!(name: "Pearl"), @user.collections.find_by!(name: "Journals")
    assert pearl.single_work?
    assert_not journals.single_work?
    add_text("Moses", pearl)
    add_text("Abraham", pearl)
    add_text("March", journals)

    get texts_path
    assert_select ".list-row-title.as-work a", text: "Pearl"
    assert_select ".list-row-title:not(.as-work) a", text: "Journals"
    assert_select ".list-row-meta", /2 books/
    assert_select ".list-row-meta", /1 text\b/
    get collection_path(pearl)
    assert_select ".page-lede", /2 books/
  end

  test "a collection needs a name" do
    post collections_path, params: { collection: { name: " ", description: "" } }
    assert_response :unprocessable_content
    assert_empty @user.collections
  end

  test "a text added from a collection's page goes into it, and can be put in none instead" do
    pearl = @user.collections.create!(name: "Pearl")
    get new_text_path(collection: pearl.slug)
    assert_select "select[name='user_text[collection_id]'] option[selected][value=?]", pearl.id.to_s

    post review_texts_path, params: { user_text: { title: "Moses", source: "Words.", collection_id: pearl.id } }
    assert_select ".texts-summary b", text: "Pearl"
    assert_equal pearl.id.to_s, css_select("form.texts-bar input[name='user_text[collection_id]']").sole["value"]
    post texts_path, params: { user_text: { title: "Moses", source: "Words.", collection_id: pearl.id } }
    post texts_path, params: { user_text: { title: "Diary", source: "Words.", collection_id: "" } }

    assert_equal [ "Moses" ], pearl.works.map(&:title)
    assert_nil @user.texts.find_by!(title: "Diary").collection
    get texts_path
    assert_select ".list-row-meta", /1 text\b/
    assert_select ".texts-group", "In no collection"
    get work_path(pearl.works.sole)
    assert_equal [ "Library", "Your Texts", "Pearl" ], css_select(".page-trail a").map(&:text)
  end

  test "a revision leaves the text in its collection" do
    pearl = @user.collections.create!(name: "Pearl")
    moses = add_text("Moses", pearl)
    get edit_text_path(moses)
    assert_select "select[name='user_text[collection_id]']", 0
    patch text_path(moses), params: { user_text: { title: "Moses", source: "Other words.", collection_id: "" } }
    assert_equal pearl, moses.reload.collection
  end

  test "deleting a collection says what goes with it, then deletes its texts and sets aside their notes" do
    pearl = @user.collections.create!(name: "Pearl")
    moses = add_text("Moses", pearl)
    add_text("Abraham", pearl)
    diary = add_text("Diary", nil)
    @user.foci.current_one.notes.create!(unit: moses.sections.sole.units.sole, content: "Rest in it")

    get delete_collection_path(pearl)
    assert_select ".delete-what strong", "2 texts"
    assert_select ".delete-what li", 2
    assert_select ".delete-final", /1 note or kept passage will be set aside/
    assert_select "button.delete-go", "Delete the collection and its 2 texts"

    delete collection_path(pearl)
    assert_redirected_to texts_path
    assert_equal "Deleted “Pearl” and its 2 texts. One note was set aside with the passages they were written on.", flash[:notice]
    assert_not Collection.exists?(pearl.id)
    assert_equal [ diary ], @user.texts.reload.to_a
    assert_equal "Rest in it", @user.detached_notes.sole.content.to_plain_text
  end

  test "an empty collection is deleted with nothing else" do
    pearl = @user.collections.create!(name: "Pearl")
    get delete_collection_path(pearl)
    assert_select ".delete-what", "It has no texts in it."
    assert_select "button.delete-go", "Delete the collection"
    delete collection_path(pearl)
    assert_equal "Deleted “Pearl”.", flash[:notice]
  end

  test "a bundled collection can't be deleted" do
    load_isaiah
    get delete_collection_path("old-testament")
    assert_response :not_found
    delete collection_path("old-testament")
    assert_response :not_found
    assert Collection.exists?(slug: "old-testament")
  end

  test "a user's own collection can be searched in and put on a shelf" do
    pearl = @user.collections.create!(name: "Pearl")
    add_text("Moses", pearl)
    get search_path(q: "Moses", collection: pearl.slug)
    assert_response :success
    assert_select "mark", "Moses"

    shelf = @user.shelves.create!(name: "Mine")
    post shelf_item_path(shelf, key: "collection-#{pearl.id}")
    assert shelf.reload.on?(pearl)
    get edit_shelf_path(shelf)
    assert_select "input[value=?][checked]", "collection-#{pearl.id}"
  end
end
