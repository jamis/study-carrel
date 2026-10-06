require "test_helper"

class SentenceSplitterTest < ActiveSupport::TestCase
  # The bundled prose was split by script/texts/sentences.py; the port must split every paragraph the same way.
  test "splits the bundled prose exactly as sentences.py did" do
    files = Dir[Rails.root.join("db/texts/*.txt")].select { File.read(it).match?(/^unit:\s*sentence$/) }
    assert files.size >= 5

    files.each do |path|
      paragraphs = Hash.new { |h, k| h[k] = [] }
      section = nil
      File.foreach(path) do |line|
        section = $1 if line =~ /\Asection:\s*(\d+)/
        paragraphs[[ section, $1 ]] << $2 if line =~ /\A(\d+)\.\d+\s+(.*)\Z/
      end
      paragraphs.each do |(s, p), sentences|
        assert_equal sentences, SentenceSplitter.split(sentences.join(" ")), "#{File.basename(path)} section #{s} paragraph #{p}"
      end
    end
  end

  test "abbreviations, initials, brackets and lone words" do
    assert_equal [ "Mr. Haddad had a rule.", "He was not joking." ], SentenceSplitter.split("Mr. Haddad had a rule. He was not joking.")
    assert_equal [ "Long walk with M. We talked." ], SentenceSplitter.split("Long walk with M. We talked.")
    assert_equal [ "Dr. Alvarez called.", "Fine. One less thing." ], SentenceSplitter.split("Dr. Alvarez called. Fine. One less thing.")
    assert_equal [ "Hm. I want to remember that." ], SentenceSplitter.split("Hm. I want to remember that.")
  end

  test "a backslash beside an ending overrides the guess, and \\\\ is a backslash" do
    sentences, markers = SentenceSplitter.split_marked('Long walk with M.\ We talked. Played Sgt\. Pepper loud.')
    assert_equal [ "Long walk with M.", "We talked.", "Played Sgt. Pepper loud." ], sentences
    assert_equal [ { kind: :break, sentence: 0, needless: false }, { kind: :keep, sentence: 2, needless: false } ], markers

    sentences, markers = SentenceSplitter.split_marked('Grand Ave.\ Then home. Saw Dr\. Who.')
    assert_equal [ "Grand Ave.", "Then home.", "Saw Dr. Who." ], sentences
    assert_equal [ true, true ], markers.map { it[:needless] }

    sentences, markers = SentenceSplitter.split_marked('A path C:\Users\me stays. Literal \\\\. here.')
    assert_equal [ 'A path C:\Users\me stays.', 'Literal \. here.' ], sentences
    assert_equal [ :stray, :stray ], markers.map { it[:kind] }
    assert_equal [ 0, 0 ], markers.map { it[:sentence] }
  end
end
