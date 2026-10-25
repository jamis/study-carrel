require "test_helper"

class FociControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
  end

  test "first run: no focus sends you to the new-focus form" do
    get root_path
    assert_redirected_to foci_path
    follow_redirect!
    assert_redirected_to new_focus_path
    get reading_path("isaiah-kjv", 40)
    assert_redirected_to new_focus_path
    get new_focus_path
    assert_response :success
  end

  test "creating a focus shows it in the band" do
    post foci_path, params: { focus: { title: "What does it mean to be holy?", description: "Set apart or good?" } }
    assert_redirected_to continue_path
    follow_redirect!
    assert_redirected_to library_path
    get reading_path("isaiah-kjv", 1)
    assert_select ".focus-title", "What does it mean to be holy?"
    assert_select ".focus-body", /Set apart or good/
  end

  test "title is required" do
    post foci_path, params: { focus: { title: "" } }
    assert_response :unprocessable_entity
    assert_equal 0, Focus.count
  end

  test "a new focus is current, and the old one stays among the others" do
    users(:one).foci.start!(title: "Old")
    post foci_path, params: { focus: { title: "New" } }
    assert_equal "New", users(:one).foci.current_one.title
    assert_equal [ "Old" ], users(:one).foci.others.map(&:title)
    assert_equal 0, Focus.archived.count
  end
end

class FociManagementTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    sign_in_as users(:one)
    @focus = users(:one).foci.start!(title: "Holy", description: "Set apart?")
  end

  test "edit updates the focus" do
    get edit_focus_path(@focus)
    assert_response :success
    patch focus_path(@focus), params: { focus: { title: "Holy, revisited" } }
    assert_redirected_to foci_path
    assert_equal "Holy, revisited", @focus.reload.title
  end

  test "blank title on update is rejected" do
    patch focus_path(@focus), params: { focus: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "the other foci are cards, and clicking one makes it current" do
    other = users(:one).foci.start!(title: "Light")
    get foci_path
    assert_select ".card-current .card-title", "Light"
    assert_select ".card:not(.card-current) .card-title", "Holy"
    assert_select ".card-past form[action=?] button.card-pick[aria-label=?]", make_current_focus_path(@focus), "Make “Holy” current"

    patch make_current_focus_path(@focus)
    assert_redirected_to foci_path
    assert_equal "Holy", users(:one).foci.current_one.title
    assert_equal [ other ], users(:one).foci.others.to_a

    follow_redirect!
    assert_select ".card-current.card-arrived .card-title", "Holy"
    # each card is named for its focus, so the view transition can carry it from one slot to the other
    assert_select "meta[name=view-transition][content=same-origin]"
    assert_select ".card-current[style=?]", "view-transition-name: focus-#{@focus.id}"
    assert_select ".card-past[style=?]", "view-transition-name: focus-#{other.id}"
    get foci_path
    assert_select ".card-arrived", false
  end

  test "the band drops the description, and nothing else" do
    get reading_path("isaiah-kjv", 40)
    assert_select ".focus[data-controller=focus] button.focus-head .focus-caret"
    assert_select ".focus-body", /Set apart\?/
    assert_select ".focus-body a, .focus-body button", 0
  end

  test "without a description, the focus is only read: no chevron, nothing to click" do
    @focus.update!(description: "")
    get reading_path("isaiah-kjv", 40)
    assert_select ".focus .focus-title", "Holy"
    assert_select ".focus[data-controller], .focus button, .focus-caret, .focus-body", 0
  end

  test "each card has an Edit, which comes back to the cards" do
    users(:one).foci.start!(title: "Light")
    get foci_path
    assert_select ".card-current a.card-act[href=?]", edit_focus_path(Focus.find_by!(title: "Light"))
    assert_select ".card-past a.card-act[href=?]", edit_focus_path(@focus), text: "Edit"
    get edit_focus_path(@focus)
    assert_select "a[href=?]", foci_path, text: "Cancel"
  end

  test "edited from its notes page, a focus goes back there" do
    get focus_notes_path(@focus)
    assert_select ".page-actions a[href=?]", edit_focus_path(@focus, back: "notes")
    get edit_focus_path(@focus, back: "notes")
    assert_select "input[type=hidden][name=back][value=notes]"
    assert_select "a[href=?]", focus_notes_path(@focus), text: "Cancel"
    patch focus_path(@focus), params: { back: "notes", focus: { title: "Holy, again" } }
    assert_redirected_to focus_notes_path(@focus)
  end

  test "the current card links to where its reading left off" do
    focus = users(:one).foci.start!(title: "What is holy?")
    get foci_path
    assert_select ".card-current .card-continue[href=?]", continue_path, text: "Choose where to begin →"
    assert_select ".card-elsewhere", false   # beginning already means choosing in the library

    focus.update!(last_unit: verse(3))
    get foci_path
    assert_select ".card-current .card-continue", /Continue at Isaiah 40:3/
    assert_select ".card-current .card-passage", /Prepare ye the way/
    assert_select ".card-current .card-elsewhere[href=?]", library_path
  end

  test "each card says how many notes it has and which works they're in" do
    @focus.notes.create!(unit: verse(3), content: "A thought")
    @focus.notes.create!(unit: verse(8), content: "Another")
    light = users(:one).foci.start!(title: "Light")

    get foci_path
    assert_select ".card-current .card-notes", "No notes yet"
    assert_select ".card:not(.card-current)" do
      assert_select ".card-desc", "Set apart?"
      assert_select ".card-notes", "2 notes in Isaiah"
      assert_select ".card-notes a[href=?]", focus_notes_path(@focus), text: "2 notes"
    end

    light.notes.create!(unit: verse(1), content: "Comfort first")
    get foci_path
    assert_select ".card-current .card-notes", "1 note in Isaiah"
    assert_select ".card-current .card-notes a[href=?]", focus_notes_path(light), text: "1 note"
  end

  test "past three works, a card names those with the most notes and counts the rest" do
    collection = Collection.create!(name: "Shelf", slug: "shelf")
    # Isaiah and Micah have two notes apiece, the rest one; Ruth comes first of those in library order.
    { "Ruth" => 1, "Esther" => 1, "Job" => 1, "Jonah" => 1, "Micah" => 2 }.each.with_index(1) do |(title, notes), position|
      section = Work.create!(title:, slug: title.downcase, collection:, position:).sections.create!(number: 1)
      notes.times { |i| @focus.notes.create!(unit: section.units.create!(number: i + 1, body: "Text"), content: title) }
    end
    @focus.notes.create!(unit: verse(3), content: "One")
    @focus.notes.create!(unit: verse(8), content: "Two")

    get foci_path
    assert_select ".card-current .card-notes", "8 notes in Ruth, Micah, Isaiah and 3 other works"
  end

  test "another reader's focuses never appear" do
    users(:two).foci.start!(title: "Someone else's question")
    get foci_path
    assert_select ".card-title", text: "Someone else's question", count: 0
    assert_select ".card-title", count: 1
  end
end
