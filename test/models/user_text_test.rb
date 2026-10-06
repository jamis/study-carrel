require "test_helper"

class UserTextTest < ActiveSupport::TestCase
  JOURNAL = <<~TEXT
    # 3 March 2024

    Woke before six. The house was quiet.
    Read Isaiah 40 again.

    # 10 March 2024

    Long walk with M. We talked.
    March 14
    Played Sgt\\. Pepper. Finished the *Emerson* essay.
  TEXT

  TALK = <<~TEXT
    Thank you. It's strange to stand up here
    after Dr. Okafor.

    I want to talk about attention.

    # Questions afterward

    Q. How do you practice attention?
  TEXT

  def text(source, **attrs) = UserText.new(title: "Journal", source:, **attrs)
  def sentences(t) = t.sections.map { |s| s.paragraphs.map(&:sentences) }

  test "with no blank line between lines of text, every line is a paragraph; blank lines around headings don't count" do
    t = text(JOURNAL)
    assert_not t.blank_lines_separate?
    assert_equal [ "3 March 2024", "10 March 2024" ], t.sections.map(&:label)
    assert_equal [ [ [ "Woke before six.", "The house was quiet." ], [ "Read Isaiah 40 again." ] ],
                   [ [ "Long walk with M. We talked." ], [ "March 14" ], [ "Played Sgt. Pepper.", "Finished the *Emerson* essay." ] ] ],
                 sentences(t)
  end

  test "blank lines separate paragraphs, joining wrapped lines; text before the first heading opens the text" do
    t = text(TALK)
    assert t.blank_lines_separate?
    assert_equal [ nil, "Questions afterward" ], t.sections.map(&:label)
    assert_equal [ "Opening", "Questions afterward" ], t.sections.map { t.label_for(it) }
    assert_equal [ "Thank you.", "It's strange to stand up here after Dr. Okafor." ], t.sections.first.paragraphs.first.sentences
    assert_equal 3, t.paragraph_count
  end

  test "checks point at likely problems" do
    messages = text(JOURNAL).checks.map(&:message)
    assert_includes messages, "Not split after “M.” If it ends a sentence, type M.\\ there."
    assert_includes messages, "Looks like a heading. Start the line with “# ” to make it one."
    assert_includes messages, "You kept this sentence together by hand."
    assert_includes messages, "Markdown formatting shows as typed (asterisks and all)."
    assert_includes text(TALK).checks.map(&:message), "Text before the first heading becomes an untitled opening section."
  end

  test "needs a title and some text, under the size limit" do
    assert_not UserText.new(title: "", source: "Hello.").valid?
    assert_not text("  \n\n").valid?
    assert_not text("# Only a heading\n").valid?
    assert_not text("a" * (UserText::MAX_BYTES + 1)).valid?
    assert text("Hello there.").valid?
  end

  test "publishing makes a private work read a sentence at a time" do
    work = text(JOURNAL, author: "Me").publish!(users(:one))
    assert_equal users(:one), work.user
    assert_match(/\Ajournal-[a-z0-9]{4}\z/, work.slug)
    assert_equal JOURNAL, work.source
    assert work.sentences?
    section = work.sections.second
    assert_equal [ "1:1", "2:1", "3:1", "3:2" ], section.units.map(&:label)
    assert_equal "Journal: 10 March 2024 3:2", section.units.last.reference
    assert_equal [ section.units.last.id ], LibrarySearch.new("Emerson", user: users(:one)).page(1).map(&:id)
    assert_empty LibrarySearch.new("Emerson", user: users(:two)).page(1)
  end

  test "a text with no headings is one section, cited by the work alone" do
    work = text("Hello there. Goodbye for now.").publish!(users(:one))
    assert_equal "Journal 1:2", work.sections.sole.units.last.reference
  end
end
