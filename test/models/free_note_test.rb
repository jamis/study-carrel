require "test_helper"

class FreeNoteTest < ActiveSupport::TestCase
  setup do
    load_isaiah
    @focus = users(:one).foci.start!(title: "Holy")
  end

  test "a note on the focus as a whole has no passage, and a focus can have many" do
    first = @focus.notes.create!(content: "Holiness keeps stooping.")
    second = @focus.notes.create!(content: "Incomparable, and imitable?")
    assert first.free?
    assert_equal [ first, second ], @focus.free_notes.to_a
  end

  test "each is numbered on its focus, and a number isn't given again once its note is gone" do
    first = @focus.notes.create!(content: "One")
    second = @focus.notes.create!(content: "Two")
    passage = @focus.notes.create!(unit: verse(3), content: "On a verse")
    assert_equal [ 1, 2 ], [ first.number, second.number ]
    assert_nil passage.number

    second.destroy!
    assert_equal 3, @focus.notes.create!(content: "Three").number
    assert_equal 1, users(:one).foci.start!(title: "Another").notes.create!(content: "Elsewhere").number
  end

  test "still one note per passage" do
    @focus.notes.create!(unit: verse(3), content: "a")
    assert_not @focus.notes.build(unit: verse(3), content: "b").valid?
  end

  test "the reread runs through the notes on passages in reading order, then those on the whole" do
    free = @focus.notes.create!(content: "Across")
    late = @focus.notes.create!(unit: verse(25), content: "Late")
    early = @focus.notes.create!(unit: verse(3), content: "Early")
    assert_equal [ early, late ], @focus.notes_in_reading_order.to_a
    assert_equal [ early, late, free ], @focus.notes_for_reread
  end

  test "it counts on the focus's card, but names no work" do
    @focus.notes.create!(unit: verse(3), content: "a")
    @focus.notes.create!(content: "b")
    assert_equal({ @focus.id => 2 }, users(:one).foci.note_counts)
    assert_equal({ @focus.id => [ [ "Isaiah", 1 ] ] }, users(:one).foci.works_read)
  end

  test "it can be labelled" do
    note = @focus.notes.create!(content: "Across")
    note.label!("the poor")
    assert_equal [ "the poor" ], note.labels.map(&:name)
  end
end
