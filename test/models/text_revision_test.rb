require "test_helper"

class TextRevisionTest < ActiveSupport::TestCase
  BEFORE = <<~TEXT
    # 3 March

    Woke before six. The house was quiet.
    "They shall mount up with wings as eagles." Not idle waiting... the kind that is full of attention.
    Dr. Alvarez called at 9 a.m. to move the appointment. Fine. One less thing on Thursday.

    # 10 March

    Long walk with M. We talked about her father, and how grief doesn't arrive on schedule. She said it comes sideways.
    March 14
    Couldn't sleep. The one I kept says only that I am tired of pretending to be certain.
  TEXT

  AFTER = <<~TEXT
    # 3 March

    A new first line. Woke before six. The house was quiet.
    "They shall mount up with wings as eagles." Not idle waiting, but the kind that is full of attention.

    # 10 March

    Long walk with Maria. We talked about her father, and how grief doesn't arrive on schedule. She said it comes sideways.

    # 14 March

    Couldn't sleep. Wrote three pages and kept one.
  TEXT

  setup do
    @user = users(:one)
    @work = UserText.new(title: "Journal", source: BEFORE).publish!(@user)
    @wait = @user.foci.start!(title: "What does it mean to wait?")
    @grief = @user.foci.create!(title: "What is grief for?", archived_at: 1.day.ago)
  end

  def unit(text) = Unit.joins(:section).where(sections: { work_id: @work.id }).find_by!(body: text)
  def note(focus, text, content) = focus.notes.create!(unit: unit(text), content:)
  def revision(source = AFTER) = TextRevision.new(@work, UserText.new(title: "Journal", source:))

  test "unchanged sentences keep their ids wherever they move; reworded ones follow the most alike sentence" do
    eagles = unit("\"They shall mount up with wings as eagles.\"")
    idle = unit("Not idle waiting... the kind that is full of attention.")
    walk = unit("Long walk with M. We talked about her father, and how grief doesn't arrive on schedule.")
    sleep = unit("Couldn't sleep.")

    revision.apply!

    assert_equal "\"They shall mount up with wings as eagles.\"", eagles.reload.body
    assert_equal [ "3 March", 2, 1 ], [ eagles.section.label, eagles.paragraph, eagles.sentence ]
    assert_equal "Not idle waiting, but the kind that is full of attention.", idle.reload.body
    assert_equal "We talked about her father, and how grief doesn't arrive on schedule.", walk.reload.body
    assert_equal [ "14 March", 1 ], [ sleep.reload.section.label, sleep.number ], "moved into the new section by its text"
    assert_equal [ "3 March", "10 March", "14 March" ], @work.sections.reload.map(&:label)
    assert_equal [ "1:1", "1:2", "1:3", "2:1", "2:2" ], @work.sections.first.units.map(&:label)
    assert_equal AFTER, @work.reload.source
    assert_equal [ unit("Wrote three pages and kept one.").id ], LibrarySearch.new("pages", user: @user).page(1).map(&:id)
  end

  test "the review sees what happens to every note and keep before anything changes" do
    note(@wait, "\"They shall mount up with wings as eagles.\"", "Strength, not its absence.")
    note(@wait, "Not idle waiting... the kind that is full of attention.", "Waiting with the door open.")
    note(@grief, "Long walk with M. We talked about her father, and how grief doesn't arrive on schedule.", "Its own calendar.")
    note(@wait, "Dr. Alvarez called at 9 a.m. to move the appointment.", "Even this.")
    @user.keeps.create!(unit: unit("The one I kept says only that I am tired of pretending to be certain."), remark: "Say it aloud.")
    @user.keeps.create!(unit: unit("Fine. One less thing on Thursday."))

    r = revision
    assert_equal({ same: 5, reworded: 2, new: 3, gone: 4 }, r.counts.slice(:same, :reworded, :new, :gone))
    fates = r.fates.to_h { [ it.record.is_a?(Keep) ? "keep: #{it.record.remark}" : it.record.content.to_plain_text, it.fate ] }
    assert_equal({ "Even this." => :detached, "keep: Say it aloud." => :detached, "keep: " => :dropped,
                   "Its own calendar." => :reworded, "Waiting with the door open." => :reworded,
                   "Strength, not its absence." => :stays }, fates)
    assert_equal "Journal: 10 March 1:2", r.fates.find { it.fate == :reworded && it.was.start_with?("Long") }.new_citation
    assert_equal 4, Note.count + Keep.count - 2, "nothing changes until it's applied"
  end

  test "applying sets aside the notes and remarks whose sentences are gone, with where they were" do
    note(@wait, "Dr. Alvarez called at 9 a.m. to move the appointment.", "<p>Even <strong>this</strong>.</p>")
    @user.keeps.create!(unit: unit("The one I kept says only that I am tired of pretending to be certain."), remark: "Say it <aloud>.")
    @user.keeps.create!(unit: unit("Fine. One less thing on Thursday."))
    @wait.update!(last_unit: unit("Fine. One less thing on Thursday."))

    revision.apply!

    assert_empty Note.all
    assert_empty Keep.all
    assert_nil @wait.reload.last_unit
    detached, kept = @user.detached_notes.partition { it.focus }
    assert_equal [ "Journal: 3 March 3:1" ], detached.map(&:citation)
    assert_equal @wait, detached.sole.focus
    assert_equal "Dr. Alvarez called at 9 a.m. to move the appointment.", detached.sole.passage
    assert_match "<strong>this</strong>", detached.sole.content.body.to_html
    assert_equal "revised", detached.sole.reason
    assert kept.sole.kept?
    assert_equal "Say it <aloud>.", kept.sole.content.to_plain_text
    assert_equal "Journal: 10 March 3:2", kept.sole.citation
  end

  test "a text revised without changes keeps everything as it was" do
    ids = Unit.joins(:section).where(sections: { work_id: @work.id }).order(:id).pluck(:id, :body)
    r = revision(BEFORE)
    assert_equal [ :same ], r.statuses.uniq
    r.apply!
    assert_equal ids, Unit.joins(:section).where(sections: { work_id: @work.id }).order(:id).pluck(:id, :body)
  end
end
