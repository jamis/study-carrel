require "test_helper"

class UserTextsControllerTest < ActionDispatch::IntegrationTest
  SOURCE = "# Monday\n\nWoke early. The house was quiet.\nRead a little.\n"

  setup do
    @user = users(:one)
    @user.foci.start!(title: "What is rest?")
    sign_in_as @user
  end

  def params(**attrs) = { user_text: { title: "Journal", author: "", source: SOURCE, **attrs } }

  test "review shows how the text will be read, without saving anything" do
    assert_no_difference -> { Work.count } do
      post review_texts_path, params: params
    end
    assert_response :success
    assert_select ".texts-summary", /1\s+section · 2\s+paragraphs · 3\s+sentences/
    assert_select ".texts-para .s", 3
    assert_select ".s[data-ref='Journal: Monday 1:2']"
    assert_equal SOURCE, css_select("input[type=hidden][name='user_text[source]']").sole["value"]
  end

  test "review sends a text without a title back to the form" do
    post review_texts_path, params: params(title: "")
    assert_response :unprocessable_content
    assert_select "textarea[name='user_text[source]']", text: SOURCE.sub(/\A\n/, "")
  end

  test "editing from the review goes back to the form with the text" do
    post review_texts_path, params: params.merge(edit: "1")
    assert_response :success
    assert_select "input[name='user_text[title]'][value=Journal]"
  end

  test "adding a text opens it in the reader" do
    assert_difference -> { @user.texts.count } do
      post texts_path, params: params
    end
    work = @user.texts.last
    assert_redirected_to reading_path(work.slug, 1, 1)
    follow_redirect!
    assert_response :success
    assert_match "Woke early.", response.body

    get library_path
    assert_select "a[href=?]", work_path(work)
    get texts_path
    assert_select ".list-row-title", "Journal"
  end

  test "a text can be deleted until something is noted or kept in it" do
    work = UserText.new(title: "Journal", source: SOURCE).publish!(@user)
    unit = work.sections.first.units.first
    @user.keeps.create!(unit:)
    delete text_path(work)
    assert Work.exists?(work.id)

    @user.keeps.delete_all
    Visit.record(@user, unit)
    delete text_path(work)
    assert_redirected_to texts_path
    assert_not Work.exists?(work.id)
    assert_not Unit.exists?(unit.id)
    assert_empty LibrarySearch.new("quiet", user: @user).page(1)
  end

  test "Your Texts has its own search and Random, which stay inside the user's texts" do
    work = UserText.new(title: "Journal", source: SOURCE).publish!(@user)
    load_isaiah
    get texts_path
    assert_select "input[type=hidden][name=texts][value=yours]"
    assert_select ".menu-random a[href=?]", random_texts_path

    get search_path(q: "quiet", texts: "yours")
    assert_select ".fv-ref", text: "Journal: Monday 1:2"
    assert_select ".search-scopes a", text: "Your Texts"
    get search_path(q: "comfort", texts: "yours")
    assert_select ".fv-ref", 0

    get random_texts_path
    assert_match %r{/read/#{work.slug}/}, response.location
  end

  test "the library lists the five most recently added texts" do
    6.times { |i| travel_to(i.days.from_now) { UserText.new(title: "Text #{i}", source: SOURCE).publish!(@user) } }
    get library_path
    assert_select ".texts-latest li", 5
    assert_select ".texts-latest li:first-child", "Text 5"
    assert_select ".texts-latest", text: /Text 0/, count: 0
    assert_select ".list-row-meta", /6 texts/
  end

  test "the reader's trail runs through Your Texts, with headings or without" do
    [ "Talk", "Journal" ].zip([ "Thank you. It is good to be here.", SOURCE ]).each do |title, source|
      work = UserText.new(title:, source:).publish!(@user)
      get reading_path(work.slug, 1, 1)
      assert_select ".trail li", text: "Your Texts", count: 2 # the rail's popover and the phone menu
    end
  end
end
