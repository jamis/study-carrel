require "test_helper"

class LabelTest < ActiveSupport::TestCase
  setup do
    load_isaiah
    @user = users(:one)
    @focus = @user.foci.start!(title: "Holy")
    @note = @focus.notes.create!(unit: verse(25), content: "The incomparable")
  end

  test "a note is put on a label by name, which is tidied and made if need be" do
    label = @note.label!("  set   apart ")
    assert_equal "set apart", label.name
    assert_equal [ label ], @note.labels
    assert_equal [ label ], @user.labels.to_a
  end

  test "a name is matched ignoring case, so the same label is found, not another made" do
    label = @note.label!("Set apart")
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    assert_equal label, other.label!("set APART")
    assert_equal 1, @user.labels.count
    assert_not @user.labels.build(name: "SET apart").valid?
  end

  test "labelling twice with one label puts the note on it once" do
    @note.label!("waiting")
    @note.label!("waiting")
    assert_equal 1, @note.note_labels.count
  end

  test "a label belongs to its user, across their focuses, and is no one else's" do
    label = @note.label!("waiting")
    later = @user.foci.start!(title: "Rest").notes.create!(unit: verse(31), content: "Renewed")
    assert_equal label, later.label!("waiting")

    theirs = users(:two).foci.start!(title: "Theirs").notes.create!(unit: verse(31), content: "Theirs")
    assert_not_equal label, theirs.label!("waiting")
    assert_not NoteLabel.new(note: theirs, label:).valid?
  end

  test "a name is short and not blank" do
    assert_not @user.labels.build(name: "   ").valid?
    assert_not @user.labels.build(name: "x" * 41).valid?
  end

  test "taking a label's last note off it drops the label" do
    label = @note.label!("waiting")
    other = @focus.notes.create!(unit: verse(31), content: "Renewed")
    other.label!("waiting")

    @note.unlabel!(label)
    assert Label.exists?(label.id)
    other.unlabel!(label)
    assert_not Label.exists?(label.id)
  end

  test "deleting a note takes its labels off, dropping any it was the last on" do
    @note.label!("waiting")
    kept = @note.label!("set apart")
    @focus.notes.create!(unit: verse(3), content: "Way").label!("set apart")

    @note.destroy!
    assert_equal [ kept ], @user.labels.reload.to_a
  end

  test "counts per label for one focus, and the other focuses a label is used under" do
    waiting = @note.label!("waiting")
    @focus.notes.create!(unit: verse(31), content: "Renewed").label!("waiting")
    rest = @user.foci.start!(title: "Rest")
    rest.notes.create!(unit: verse(1), content: "Comfort").label!("waiting")

    assert_equal({ waiting.id => 2 }, @focus.label_counts)
    assert_equal({ waiting.id => [ "Rest" ] }, @focus.labels_elsewhere)
    assert_equal({ waiting.id => [ "Holy" ] }, rest.labels_elsewhere)
  end

  test "a note set aside keeps its labels' names, and labels on no other note go" do
    @note.label!("waiting")
    shared = @note.label!("set apart")
    @focus.notes.create!(unit: verse(3), content: "Way").label!("set apart")

    DetachedNote.set_aside!(Unit.where(id: verse(25).id), reason: "revised")
    assert_equal [ "set apart", "waiting" ], @user.detached_notes.sole.label_names
    assert_equal [ shared ], @user.labels.reload.to_a
  end

  test "the scratchpad is the focus's own rich text" do
    @focus.update!(scratchpad: "<p>Compare Amos 5?</p>")
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text
  end
end
