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

  test "a blank name is refused when labelling by name" do
    assert_raises(ActiveRecord::RecordInvalid) { @note.label!("   ") }
    assert_empty @user.labels
  end

  test "two notes found to go together make an unnamed label, known by the first" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    assert_nil group.name
    assert_not group.named?
    assert_equal @note, group.example_note
    assert_equal [ group ], @note.labels
    assert_equal [ group ], other.labels
  end

  test "any number of unnamed labels, while names stay unique" do
    a = @focus.notes.create!(unit: verse(3), content: "a")
    b = @focus.notes.create!(unit: verse(4), content: "b")
    @note.group_with!(a)
    @note.group_with!(b)
    assert_equal 2, @user.labels.count
  end

  test "an unnamed label is described by its example, from every note in it" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    assert_equal @note, group.face_note

    alone = @focus.notes.create!(unit: verse(4), content: "Valleys")
    group.update!(example_note: alone)
    alone.join!(group)
    assert_equal alone, group.face_note
  end

  test "unnamed labels are lettered in turn, a letter never handed out twice" do
    a = @focus.notes.create!(unit: verse(3), content: "a")
    b = @focus.notes.create!(unit: verse(4), content: "b")
    first = @note.group_with!(a)
    second = @note.group_with!(b)
    assert_equal [ "A", "B" ], [ first.letter, second.letter ]

    b.unlabel!(second)
    @note.unlabel!(second)
    assert_equal "C", @note.group_with!(b).letter
    assert_nil @note.label!("waiting").number
  end

  test "a label keeps its letter through being named, and a named one takes one when its name goes" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    group.rename!("set apart")
    group.rename!("")
    assert_equal "A", group.reload.letter

    label = @note.label!("waiting")
    label.rename!("")
    assert_equal "B", label.reload.letter
  end

  test "letters run on past Z" do
    letters = [ 1, 26, 27, 52, 53, 702, 703 ].map { Label.new(number: it).letter }
    assert_equal %w[ A Z AA AZ BA ZZ AAA ], letters
  end

  test "taking its example off moves the example on; taking the last note off drops it" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    @note.unlabel!(group)
    assert_equal other, group.reload.example_note
    other.unlabel!(group)
    assert_not Label.exists?(group.id)
  end

  test "deleting its example moves the example on" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    @note.destroy!
    assert_equal other, group.reload.example_note
  end

  test "an unnamed label is named, renamed, and can lose its name again" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    group.rename!("  set   apart ")
    assert_equal "set apart", group.reload.name
    group.rename!("")
    assert_nil group.reload.name
    assert_equal @note, group.example_note
  end

  test "a named label losing its name becomes known by its first note" do
    label = @note.label!("waiting")
    label.rename!(" ")
    assert_nil label.reload.name
    assert_equal @note, label.example_note
  end

  test "a name already given to another label is refused, not merged" do
    @note.label!("waiting")
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    group = @note.group_with!(other)
    assert_raises(ActiveRecord::RecordInvalid) { group.rename!("Waiting") }
    assert_nil group.reload.name
  end

  test "unnamed labels sort after named ones, in the order they were made" do
    other = @focus.notes.create!(unit: verse(3), content: "Wilderness")
    first = @note.group_with!(other)
    second = other.group_with!(@note)
    zeal = @note.label!("zeal")
    awe = @note.label!("awe")
    assert_equal [ awe, zeal, first, second ], @user.labels.alphabetical.to_a
  end

  test "a note set aside keeps only its named labels' names" do
    @note.label!("waiting")
    @note.group_with!(@focus.notes.create!(unit: verse(3), content: "Way"))
    DetachedNote.set_aside!(Unit.where(id: verse(25).id), reason: "revised")
    assert_equal [ "waiting" ], @user.detached_notes.sole.label_names
  end

  test "the scratchpad is the focus's own rich text" do
    @focus.update!(scratchpad: "<p>Compare Amos 5?</p>")
    assert_equal "Compare Amos 5?", @focus.reload.scratchpad.to_plain_text
  end
end
