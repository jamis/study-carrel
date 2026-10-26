require "test_helper"

class RereadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @late = @focus.notes.create!(unit: verse(25), content: "The incomparable")
    @early = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    sign_in_as users(:one)
  end

  test "every note, in reading order, the first one lit" do
    get focus_notes_path(@focus)
    assert_response :success
    assert_select ".rr-row[data-note-id] .rr-cite" do |refs|
      assert_equal [ "Isaiah 40:3", "Isaiah 40:25" ], refs.map { it.text.strip }
    end
    assert_select ".rr-row.here", 1
    assert_select "#reread_note_#{@early.id}.here"
    assert_select ".rr-row .rr-ref[href=?]", reading_path("isaiah-kjv", 40, 25)
  end

  test "opens where it left off" do
    patch focus_reread_path(@focus), params: { note_id: @late.id }, as: :json
    assert_response :no_content
    assert_equal @late, @focus.reload.reread_note

    get focus_notes_path(@focus)
    assert_select "#reread_note_#{@late.id}.here"
  end

  test "where it left off is one of the focus's own notes" do
    other = users(:one).foci.start!(title: "Rest").notes.create!(unit: verse(31), content: "Renewed")
    patch focus_reread_path(@focus), params: { note_id: other.id }, as: :json
    assert_response :not_found
  end

  test "rereads only the notes carrying one label" do
    waiting = @late.label!("waiting")
    get focus_notes_path(@focus, label: waiting.id)
    assert_select ".rr-row[data-note-id]", 1
    assert_select ".rr-row[data-note-id] .rr-cite", "Isaiah 40:25"
    assert_select ".rr-filter", /labelled “waiting”/
    assert_select ".rr-filter-band", /Only the 1 note labelled “waiting”/
    assert_select ".rr-filter-band a[href=?]", focus_notes_path(@focus, at: @late.id), text: "Show all 2"
    assert_select ".rr-filter-band .rr-filter-rename button", "Rename"
    assert_select ".rr-filter-band input.rr-name[value=?]", "waiting"
  end

  test "each pill rereads only its label's notes, from that note, and Remove is there to be offered" do
    waiting = @late.label!("waiting")
    get focus_notes_path(@focus)
    assert_select "#reread_note_#{@late.id} .rr-chip a.rr-chip-face[href=?]", focus_notes_path(@focus, label: waiting.id, at: @late.id), "waiting"
    assert_select "#reread_note_#{@late.id} .rr-chip button.rr-chip-take[data-label-id=?]", waiting.id.to_s
    assert_select ".rr-filter-band", 0
  end

  test "opens on the note asked for, if it's among those shown" do
    waiting = @early.label!("waiting")
    get focus_notes_path(@focus, at: @early.id)
    assert_select "#reread_note_#{@early.id}.here"
    get focus_notes_path(@focus, label: waiting.id, at: @late.id)
    assert_select "#reread_note_#{@early.id}.here"
  end

  test "the labels in use: their notes' chips, the cloud sized by count, tallies, and labels from other focuses" do
    @late.label!("set apart")
    @early.label!("set apart")
    @early.label!("wilderness")
    users(:one).foci.create!(title: "Rest", made_current_at: 1.day.ago).notes.create!(unit: verse(31), content: "x").label!("waiting")

    get focus_notes_path(@focus)
    assert_select "#reread_note_#{@early.id} .rr-chip", 2
    assert_select ".rr-cloud .rr-word:not(.away)", 2
    assert_select ".rr-cloud .rr-word.away", "waiting"
    assert_select ".rr-cloud .rr-word[data-label-name=?][title*=?]", "set apart", "2 notes"
    assert_select ".rr-tallies .rr-tally", 2
    assert_select ".rr-tallies .rr-tally:first-child .rr-ticks i.on", 2
  end

  test "an unnamed label shows by its letter, the same on each of its notes: in the chips, the cloud, the tallies and the filter" do
    group = @late.group_with!(@early)
    get focus_notes_path(@focus)
    assert_select "#reread_note_#{@early.id} .rr-chip .lf", "group A"
    assert_select "#reread_note_#{@late.id} .rr-chip .lf", "group A"
    assert_select "#reread_note_#{@early.id} .rr-chip-face[title^=?]", "Reread only the notes in group A (like Isaiah 40:25: "
    assert_select "#reread_note_#{@late.id} .rr-chip-face[title^=?]", "Reread only the notes in group A (like Isaiah 40:25: "
    assert_select ".rr-cloud .rr-word[data-label-id=?]:not([data-label-name])", group.id.to_s, text: "group A"
    assert_select ".rr-tallies .rr-tally-name", "group A"
    assert_select ".rr-filter-menu .menu-item", /group A/

    get focus_notes_path(@focus, label: group.id)
    assert_select ".rr-filter", /in group A/
  end

  test "the current focus's notes on passages get the reader's editor; a past focus's are only read" do
    get focus_notes_path(@focus)
    assert_select "#reread_note_#{@late.id}[data-editor-url=?]", unit_note_path(verse(25))

    users(:one).foci.start!(title: "Rest")
    get focus_notes_path(@focus)
    assert_response :success
    assert_select "#reread_note_#{@late.id}[data-editor-url=?]", ""
  end

  test "the scratchpad is saved, the current focus's or a past one's" do
    put focus_scratchpad_path(@focus), params: { scratchpad: { content: "<p>Compare Amos 5?</p>" } }, as: :json
    assert_response :no_content
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text

    users(:one).foci.start!(title: "Rest")
    put focus_scratchpad_path(@focus), params: { scratchpad: { content: "<p>Later</p>" } }, as: :json
    assert_equal "Later", @focus.reload.scratchpad.to_plain_text
    get focus_notes_path(@focus)
    assert_select ".reread-pad .preview", "Later"
  end

  test "an edit saved from the reader updates the note's row on the reread page" do
    put unit_note_path(verse(25)), params: { focus_id: @focus.id, note: { content: "<p>Changed</p>" } }, as: :turbo_stream
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(verse(25), :reread_text)}"), response.body
    assert_match "Changed", response.body
  end
end

class NoteLabelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    @note = @focus.notes.create!(unit: verse(25), content: "The incomparable")
    sign_in_as users(:one)
  end

  test "putting a note on a label by name redraws its chips and the labels panel" do
    post focus_note_labels_path(@focus, @note), params: { name: "Set apart" }, as: :turbo_stream
    assert_response :success
    assert_equal [ "Set apart" ], @note.labels.pluck(:name)
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@note, :labels)}"), response.body
    assert_match %(target="reread_labels"), response.body
  end

  test "taking it off" do
    label = @note.label!("waiting")
    delete focus_note_label_path(@focus, @note, label), as: :turbo_stream
    assert_response :success
    assert_empty @note.labels.reload
  end

  test "a blank name is refused" do
    post focus_note_labels_path(@focus, @note), params: { name: "  " }, as: :turbo_stream
    assert_response :unprocessable_entity
  end

  test "a past focus's notes can be labelled too" do
    users(:one).foci.start!(title: "Rest")
    post focus_note_labels_path(@focus, @note), params: { name: "waiting" }, as: :turbo_stream
    assert_response :success
  end

  test "a note found to go with another makes an unnamed label of the two, redrawing both notes' chips" do
    other = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    post focus_note_labels_path(@focus, @note), params: { with_note_id: other.id }, as: :turbo_stream
    assert_response :success
    group = @note.labels.sole
    assert_nil group.name
    assert_equal [ group ], other.labels
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@note, :labels)}"), response.body
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(other, :labels)}"), response.body
    assert_match "like Isaiah 40:25", response.body
    assert_match %r{action="replace" target="reread_filter_menu">.*group #{group.letter}<small>2</small>}m, response.body
  end

  test "a note goes on an unnamed label by its id" do
    a = @focus.notes.create!(unit: verse(3), content: "a")
    b = @focus.notes.create!(unit: verse(4), content: "b")
    group = a.group_with!(b)
    post focus_note_labels_path(@focus, @note), params: { label_id: group.id }, as: :turbo_stream
    assert_response :success
    assert_equal [ group ], @note.labels
  end

  test "taking the last but one note off redraws the one left" do
    other = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    group = @note.group_with!(other)
    delete focus_note_label_path(@focus, other, group), as: :turbo_stream
    assert_response :success
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@note, :labels)}"), response.body
    assert_match %(<span class="lf-letter">A</span>), response.body
  end

  test "a note can't be grouped with itself, or with another focus's note" do
    post focus_note_labels_path(@focus, @note), params: { with_note_id: @note.id }, as: :turbo_stream
    assert_response :unprocessable_entity
    elsewhere = users(:one).foci.create!(title: "Rest", made_current_at: 1.day.ago).notes.create!(unit: verse(31), content: "x")
    post focus_note_labels_path(@focus, @note), params: { with_note_id: elsewhere.id }, as: :turbo_stream
    assert_response :not_found
  end

  test "another user's labels, notes and focuses are a 404" do
    theirs = users(:two).foci.start!(title: "Theirs").notes.create!(unit: verse(31), content: "Theirs")
    their_label = theirs.label!("theirs")
    post focus_note_labels_path(@focus, @note), params: { label_id: their_label.id }, as: :turbo_stream
    assert_response :not_found
    post focus_note_labels_path(@focus, @note), params: { with_note_id: theirs.id }, as: :turbo_stream
    assert_response :not_found
    patch focus_label_path(@focus, their_label), params: { name: "mine now" }, as: :turbo_stream
    assert_response :not_found
    patch focus_label_path(theirs.focus, @note.label!("mine")), params: { name: "x" }, as: :turbo_stream
    assert_response :not_found
    assert_equal "theirs", their_label.reload.name
  end

  test "naming an unnamed label redraws its notes' chips" do
    other = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    group = @note.group_with!(other)
    patch focus_label_path(@focus, group), params: { name: "Holy otherness" }, as: :turbo_stream
    assert_response :success
    assert_equal "Holy otherness", group.reload.name
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(other, :labels)}"), response.body
    assert_match %(target="reread_labels"), response.body
    assert_match %(targets=".#{ActionView::RecordIdentifier.dom_id(group, :phrase)}"), response.body
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(group, :naming)}"), response.body
  end

  test "renaming, and taking the name away again" do
    label = @note.label!("waiting")
    patch focus_label_path(@focus, label), params: { name: "patience" }, as: :turbo_stream
    assert_equal "patience", label.reload.name
    patch focus_label_path(@focus, label), params: { name: " " }, as: :turbo_stream
    assert_response :success
    assert_nil label.reload.name
    assert_equal @note, label.example_note
  end

  test "a name already taken is refused, saying so" do
    @note.label!("waiting")
    other = @focus.notes.create!(unit: verse(3), content: "The wilderness")
    group = @note.group_with!(other)
    patch focus_label_path(@focus, group), params: { name: "Waiting" }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "You already have a label called “Waiting”.", response.body
    assert_nil group.reload.name
  end
end

class RereadWaysInTest < ActionDispatch::IntegrationTest
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
    sign_in_as users(:one)
  end

  test "the reread is the notes page: its old address goes there, keeping the label" do
    waiting = @focus.notes.create!(unit: verse(3), content: "a").label!("waiting")
    get focus_reread_path(@focus)
    assert_redirected_to focus_notes_path(@focus)
    get focus_reread_path(@focus, label: waiting.id)
    assert_redirected_to focus_notes_path(@focus, label: waiting.id)
  end

  test "no separate way in from the card or the menu" do
    @focus.notes.create!(unit: verse(3), content: "a")
    get foci_path
    assert_select "a[href=?]", focus_reread_path(@focus), 0
    assert_select ".card-notes a[href=?]", focus_notes_path(@focus)
  end
end
