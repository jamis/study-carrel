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

  SONG = <<~TEXT
    [Verse 1]
    The river’s down to stones again,
      the dock leans like a tired man.

    [Chorus]
    So I’ll wait by the low water,
    keep it burning on.

    [Chorus]
    So I’ll wait by the low water,
    keep it burning on.

    Repeat chorus (x2)
  TEXT

  POEMS = <<~TEXT
    # Lamp

    Before the house wakes
    I turn the lamp down low.

    Reservoir

    The water held the sky so still
    I could not tell which one was deep.
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

  test "poetry: blank lines separate stanzas, line breaks are kept, and lines are trimmed" do
    t = text(SONG, form: "poetry")
    assert t.poetry?
    assert_equal [ nil ], t.sections.map(&:label)
    assert_equal [ [ "[Verse 1]\nThe river’s down to stones again,\nthe dock leans like a tired man." ],
                   *[ [ "[Chorus]\nSo I’ll wait by the low water,\nkeep it burning on." ] ] * 2, [ "Repeat chorus (x2)" ] ],
                 t.sections.sole.paragraphs.map(&:sentences)
    assert_equal [ 4, 4, 10 ], [ t.paragraph_count, t.sentence_count, t.line_count ]
    assert_equal "Low Water, stanza 2", text(SONG, title: "Low Water", form: "poetry").reference(t.sections.sole, 2, 1)
  end

  test "poetry with no blank lines is one stanza a section" do
    t = text("# One\nA line\nAnother line\n# Two\nOnly this", form: "poetry")
    assert_equal [ [ "A line\nAnother line" ], [ "Only this" ] ], t.sections.map { |s| s.paragraphs.map { it.sentences.sole } }
  end

  test "poetry checks: part labels as one quiet check, repeats, stanzas sung twice, indents, a title without #" do
    checks = text(SONG, form: "poetry").checks
    labels = checks.find(&:quiet)
    assert_equal "Part labels, like “[Verse 1]”, in 3 places. Each is read as a line of its stanza; delete them if you’d rather not see them.", labels.message
    messages = checks.map(&:message)
    assert_includes messages, "An instruction to repeat. It’s read as typed; paste the words in again where they repeat to read them there."
    assert_includes messages, "This stanza comes 2 times. Each is read, and noted, on its own."
    assert_includes messages, "An indented line loses its indent."
    assert_equal checks.map(&:line).sort, checks.map(&:line)

    title = text(POEMS, form: "poetry").checks.sole
    assert_equal [ "Looks like a title. Start the line with “# ” to make it a section of its own.", 6, 0, 1 ],
                 [ title.message, title.line, title.section, title.paragraph ]
  end

  test "verse is told from prose by its short, open lines" do
    assert text(SONG).looks_like_verse?
    assert_not text(JOURNAL).looks_like_verse?
    assert_not text(TALK).looks_like_verse?
  end

  test "publishing poetry makes a work read a stanza at a time" do
    work = text(POEMS, form: "poetry").publish!(users(:one))
    assert_not work.sentences?
    assert_equal "stanza", work.unit_name
    assert_equal "poetry", UserText.form_of(work)
    units = work.sections.sole.units
    assert_equal [ [ 1, nil, nil ], [ 2, nil, nil ], [ 3, nil, nil ] ], units.map { [ it.number, it.paragraph, it.sentence ] }
    assert_equal "Before the house wakes\nI turn the lamp down low.", units.first.body
    assert_equal "Journal: Lamp, stanza 3", units.last.reference
    assert_equal [ units.last.id ], LibrarySearch.new("sky still", user: users(:one)).page(1).map(&:id)
  end

  MOSES = <<~TEXT
    The Words of God, Which He Spake unto Moses

    # 1

    1 The words of God, which he spake unto Moses
    at a time when Moses was caught up
    into an exceedingly high mountain,

    2. And he saw God face to face, and he talked with him.
    3: And God spake unto Moses, saying: Behold, I am the Lord God Almighty.

    # 2

    2 And it came to pass that the Lord spake *unto* Moses.
    4 Behold, I reveal unto you concerning this heaven.
    3 And I, God, said: Let there be light.
    5
  TEXT

  test "scripture: a numbered line starts a verse, lines after it are joined, and text before the first verse is left out" do
    t = text(MOSES, form: "scripture", title: "Moses")
    assert t.valid?
    assert_equal [ "1", "2" ], t.kept_sections.map(&:label)
    assert_equal [ [ 1, 2, 3 ], [ 2, 4, 3 ] ], t.kept_sections.map { |s| s.paragraphs.map(&:number) }
    assert_equal "The words of God, which he spake unto Moses at a time when Moses was caught up into an exceedingly high mountain,",
                 t.kept_sections.first.paragraphs.first.text
    assert_equal 6, t.sentence_count
    assert_equal "Moses 1:3", t.reference(t.kept_sections.first, 3, 1)
    assert_equal "Moses 2:4", t.reference(t.kept_sections.last, 2, 1)
  end

  test "scripture checks: text left out, numbering that skips or goes back, an empty verse, Markdown" do
    messages = text(MOSES, form: "scripture").checks.map { [ it.line, it.message ] }
    assert_equal [
      [ 1, "Before the first verse, so it’s left out. Start it with “# ” to make it a heading, or with a number to make it a verse." ],
      [ 14, "The section starts at verse 2." ],
      [ 14, "Markdown formatting shows as typed (asterisks and all)." ],
      [ 15, "No verse 3: numbering jumps to 4." ],
      [ 16, "Verse 3 comes after verse 4. Verses are read in order of their numbers." ],
      [ 17, "Verse 5 has no words, so it’s left out." ]
    ], messages
  end

  test "scripture with a verse number twice in a section, or with no verses, can't be added" do
    t = text("# 1\n\n1 In the beginning.\n2 And the earth.\n1 Again.", form: "scripture")
    assert_not t.valid?
    assert_equal [ "has verse 1 twice in “1” (line 5); each verse in a section needs its own number" ], t.errors[:source]
    assert_not text("Just words.", form: "scripture").valid?
    assert text("# 1\n\n1 In the beginning.\n\n# 2\n\n1 Again.", form: "scripture").valid?
  end

  test "publishing scripture makes a work read a verse at a time, numbered as typed" do
    work = text(MOSES, form: "scripture", title: "Moses").publish!(users(:one))
    assert_equal "verse", work.unit_name
    assert_equal "scripture", UserText.form_of(work)
    units = work.sections.last.units
    assert_equal [ [ 2, nil, nil ], [ 3, nil, nil ], [ 4, nil, nil ] ], units.map { [ it.number, it.paragraph, it.sentence ] }
    assert_equal "Moses 2:3", units.second.reference
    assert_equal "And I, God, said: Let there be light.", units.second.body
    assert_equal "Moses, verse 2", text("1 One.\n2 Two.", form: "scripture", title: "Moses").publish!(users(:one)).sections.sole.units.last.reference
  end

  test "numbered verses are told from prose and poetry" do
    assert text(MOSES).looks_like_scripture?
    assert_not text(JOURNAL).looks_like_scripture?
    assert_not text(POEMS).looks_like_scripture?
  end

  test "the form is prose, poetry or scripture" do
    assert_not text("Hello.", form: "verse").valid?
  end

  test "a text with no headings is one section, cited by the work alone" do
    work = text("Hello there. Goodbye for now.").publish!(users(:one))
    assert_equal "Journal 1:2", work.sections.sole.units.last.reference
  end
end
