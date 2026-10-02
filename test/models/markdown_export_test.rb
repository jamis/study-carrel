require "test_helper"

class MarkdownExportTest < ActiveSupport::TestCase
  setup do
    TextLoader.load_all
    @focus = Focus.start!(title: "What does it mean to be holy?", description: "Set apart, or good?")
  end

  test "renders the focus, quoted verses and converted notes in reading order" do
    @focus.notes.create!(unit: Unit.find_by!(number: 25), content: "<p>Later, <strong>bold</strong> thought.</p>")
    @focus.notes.create!(unit: Unit.find_by!(number: 3), content: "<p>First.</p><ul><li>one</li><li>two</li></ul>")
    @focus.notes.create!(unit: Unit.find_by!(number: 3), content: "<h2>Heading</h2><p>Second.</p>")

    md = MarkdownExport.new(@focus).to_s

    assert md.start_with?("# What does it mean to be holy?\n\nSet apart, or good?\n\n## Isaiah 40:3\n\n> The voice of him that crieth")
    assert_operator md.index("## Isaiah 40:3"), :<, md.index("## Isaiah 40:25")
    assert_includes md, "Later, **bold** thought."
    assert_includes md, "- one\n- two"
    assert_includes md, "#### Heading"
    assert md.end_with?("\n")
  end

  test "filename comes from the focus title" do
    assert_equal "what-does-it-mean-to-be-holy.md", MarkdownExport.new(@focus).filename
  end

  test "other foci's notes are not included" do
    old = Focus.create!(title: "Old", archived_at: 1.day.ago)
    old.notes.create!(unit: Unit.find_by!(number: 1), content: "<p>not mine</p>")
    refute_includes MarkdownExport.new(@focus).to_s, "not mine"
  end
end
