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

  test "deleting a text removes its sentences, history and search entries" do
    work = UserText.new(title: "Journal", source: SOURCE).publish!(@user)
    unit = work.sections.first.units.first
    Visit.record(@user, unit)
    delete text_path(work)
    assert_redirected_to texts_path
    assert_not Work.exists?(work.id)
    assert_not Unit.exists?(unit.id)
    assert_empty Visit.where(unit_id: unit.id)
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

  test "the reader names the sections either side by their own names, the work's title only as a tooltip" do
    work = UserText.new(title: "Quick to Help, Slow to Judge", source: "# Being Present\n\nOne.\n\n# Showing Up\n\nTwo.\n\n# Withholding Judgment\n\nThree.\n").publish!(@user)
    get reading_path(work.slug, 2, 1)
    assert_select "#rail-library .trail-sides a[title='Quick to Help, Slow to Judge: Being Present']", "‹ Being Present"
    assert_select "#rail-library .trail-sides a.trail-next", "Withholding Judgment ›"
  end

  REVISED = "# Monday\n\nWoke early. Coffee first.\nRead a little more.\n"

  def noted_text
    work = UserText.new(title: "Journal", source: SOURCE).publish!(@user)
    units = work.sections.first.units.index_by(&:body)
    @user.foci.current_one.notes.create!(unit: units.fetch("Woke early."), content: "Early, again.")
    @user.foci.current_one.notes.create!(unit: units.fetch("Read a little."), content: "Which book?")
    @user.keeps.create!(unit: units.fetch("The house was quiet."), remark: "Quiet as rest.")
    work
  end

  test "revising: the form starts from the text as it was, and the review says what happens to each note and keep" do
    work = noted_text
    get edit_text_path(work)
    assert_select "h2", "Revise “Journal”"
    assert_select "textarea[name='user_text[source]']", text: SOURCE.sub(/\A\n/, "")

    patch review_text_path(work), params: params(source: REVISED)
    assert_response :success
    assert_select ".texts-changes summary", /2 of 3 notes and keeps affected/
    assert_select ".texts-fate", 3
    assert_select ".texts-fate .head", text: /Note in “What is rest\?” stays, sentence unchanged/
    assert_select ".texts-fate .head", text: /Kept, with a remark remark set aside/
    assert_select ".texts-fate .was", text: "WasRead a little."
    assert_select ".texts-fate .now", text: "NowRead a little more."
    assert_select "form.texts-bar[action=?] input[name=_method][value=patch]", text_path(work)
    assert_equal SOURCE, work.reload.source, "the review saves nothing"
  end

  test "saving a revision keeps what survives and sets aside the rest, shown after the focus's notes and on Kept" do
    work = noted_text
    patch text_path(work), params: params(source: REVISED)
    assert_redirected_to texts_path
    assert_equal "Saved “Journal”. One note was set aside with the passages they were written on.", flash[:notice]
    assert_equal REVISED, work.reload.source
    assert_equal [ "Early, again.", "Which book?" ], Note.all.map { it.content.to_plain_text }.sort

    get notes_path
    assert_select ".detached", 0, "the notes both survived"
    get kept_path
    assert_select ".detached .fv-ref", "Journal: Monday 1:2"
    assert_select ".detached .fv-quote", "The house was quiet."
    assert_select ".detached .fv-note", /Quiet as rest/
    get export_notes_path
    assert_no_match "Quiet as rest", response.body, "a kept remark belongs to no focus"
  end

  test "deleting a text with notes sets them aside first; a set-aside note can be discarded, by its owner only" do
    work = noted_text
    get texts_path
    assert_select "form[data-turbo-confirm*='3 notes and kept passages will be set aside']"
    delete text_path(work)
    assert_not Work.exists?(work.id)
    assert_equal 3, @user.detached_notes.count
    assert_equal [ "deleted" ], @user.detached_notes.pluck(:reason).uniq

    get export_notes_path
    assert_match "## From passages that changed or were removed\n\n### Journal: Monday 1:1\n\n> Woke early.\n\nEarly, again.", response.body

    detached = @user.detached_notes.first
    sign_in_as users(:two)
    delete detached_note_path(detached)
    assert_response :not_found
    sign_in_as @user
    delete detached_note_path(detached)
    assert_not DetachedNote.exists?(detached.id)
  end

  POEM = "# Lamp\n\nBefore the house wakes\nI turn the lamp down low,\nand the window gives me back\na face I almost know.\n\nThe kettle ticks. The dark\nleans in to hear\n"

  test "poetry: the review shows stanzas with their line breaks, and adding it reads a stanza at a time" do
    post review_texts_path, params: params(source: POEM, form: "poetry")
    assert_response :success
    assert_select ".texts-summary", /1\s+section · 2\s+stanzas · 6\s+lines/
    assert_select ".texts-stanza", 2
    assert_equal "2The kettle ticks. The dark\nleans in to hear", css_select(".texts-stanza[data-ref='Journal: Lamp, stanza 2']").sole.text
    assert_select ".texts-legend", /Each stanza is shaded in turn/
    assert_select "form.texts-bar input[name='user_text[form]'][value=poetry]"

    post texts_path, params: params(source: POEM, form: "poetry")
    work = @user.texts.last
    assert_equal "stanza", work.unit_name
    follow_redirect!
    assert_select ".now .ref-unit", ", stanza 1"
    get texts_path
    assert_select ".list-row-meta", /2 stanzas/
  end

  test "verse added as prose: the form and the review offer to read it as poetry" do
    get new_text_path
    assert_select "input[type=radio][name='user_text[form]'][value=prose][checked]"
    assert_select ".texts-verse-hint[hidden]"

    post review_texts_path, params: params(source: POEM)
    assert_select ".texts-rule form input[name='user_text[form]'][value=poetry]"
    assert_select ".texts-rule button", "This looks like verse: read it as poetry instead"
    post review_texts_path, params: params(source: SOURCE)
    assert_select ".texts-rule form", 0
  end

  test "a revision keeps the text's form, whatever is posted" do
    work = UserText.new(title: "Journal", source: POEM, form: "poetry").publish!(@user)
    get edit_text_path(work)
    assert_select "input[type=radio][value=poetry][checked][disabled]"
    assert_select "legend", /a revision keeps its form/

    patch review_text_path(work), params: params(source: POEM, form: "prose")
    assert_select ".texts-stanza", 2
    assert_select ".texts-changes .texts-tally", /2 stanzas unchanged/
    patch text_path(work), params: params(source: POEM.sub("dark", "night"), form: "prose")
    assert_equal "stanza", work.reload.unit_name
    assert_equal [ nil ], work.sections.sole.units.pluck(:sentence).uniq
  end

  test "another user can't revise someone's text" do
    work = noted_text
    sign_in_as users(:two)
    get edit_text_path(work)
    assert_response :not_found
    patch review_text_path(work), params: params(source: REVISED)
    assert_response :not_found
    patch text_path(work), params: params(source: REVISED)
    assert_response :not_found
    assert_equal SOURCE, work.reload.source
  end
end
