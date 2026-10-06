# Splits a paragraph of prose into sentences: a port of script/texts/sentences.py, which splits the bundled prose when
# it is built, so a user's own text is read the same way. Keep the two in step (test/models/sentence_splitter_test.rb
# checks this one against the bundled files).
#
# A sentence ends at . ? or ! (with any closing quotes or brackets) followed by a space and a capital letter or an
# opening quote, unless the period ends a known abbreviation ("Mr.") or an initial ("J. Smith"), the text so far is only
# a list number, or it falls inside brackets opened within the sentence. A paragraph with dot leaders is a table, kept
# whole. A lone word ending in a period ("Hermit.", "Fine.") joins the sentence after it, or the one before at the end.
#
# In a user's text a backslash beside the punctuation overrides the guess (see .split_marked): "Sgt\. Pepper" is not an
# ending, "with M.\ We" is one, and "\\" is a literal backslash.
module SentenceSplitter
  ABBREVIATIONS = %w[
    Mr Mrs Messrs Dr St Mt Esq Rev Capt Col Gen Lieut Hon Prof Sen Jr Sr Mme Mlle Co No
    viz vs etc cf ch chap vol pp ibid Ib Id Lib Ep
  ].to_set

  # Python's \s matches any Unicode space, so [[:space:]] here.
  ENDING = /([.?!][”’")\]]*)[[:space:]]+(?=[“‘"(\[]?[A-Z])/
  FRAGMENT = /\A(?:[“‘(\[]?[A-Za-zÀ-ÿ’]+\.[”’)\]]*|[^A-Za-zÀ-ÿ]+)\z/

  # Stand-ins for the markers while splitting, from Unicode's private use area.
  LITERAL, KEEP, BREAK = "\u{E000}", "\u{E001}", "\u{E002}"

  module_function

  def split(text)
    return [ text ] if text.match?(/\.{6,}[[:space:]]*\$?[[:space:]]*\d/)

    out, start = [], 0
    text.scan(ENDING) do
      m = Regexp.last_match
      before = text[start...m.begin(0)]
      word = before[/([A-Za-z]+)\z/, 1]
      if m[1] == "."
        next if word && (ABBREVIATIONS.include?(word) || word.match?(/\A[A-Z]\z/))
        next if before.match?(/\A[[:space:]]*\d+\z/)
      end
      next if bracket_depth(text[start...m.end(1)].sub(/\A[\[(]+/, "")) > 0

      out << text[start...m.end(1)].strip
      start = m.end(0)
    end
    out << text[start..].strip
    join_fragments(out.reject(&:empty?))
  end

  def join_fragments(sentences)
    out, carry = [], []
    sentences.each do |s|
      if s.match?(FRAGMENT)
        carry << s
      else
        out << [ *carry, s ].join(" ")
        carry = []
      end
    end
    if carry.any?
      out.empty? ? out << carry.join(" ") : out[-1] = [ out[-1], *carry ].join(" ")
    end
    out
  end

  def bracket_depth(text)
    [ text.count("(") - text.count(")"), 0 ].max + [ text.count("[") - text.count("]"), 0 ].max
  end

  # Splits a paragraph that may hold backslash markers. Returns the sentences, with the markers gone, and the markers
  # found: { kind: :keep / :break / :stray, sentence: index, needless: true when the split would be the same without
  # it }. A stray backslash is one beside nothing it can mark; it stays in the text.
  def split_marked(text)
    marked = mark(text)
    sentences = marked.split(/#{BREAK}[[:space:]]*/o).reject { it.strip.empty? }.flat_map { split(it) }
    [ sentences.map { unmark(it) }, markers(marked, sentences) ]
  end

  def mark(text)
    text.gsub("\\\\", LITERAL).gsub(/\\([.?!])/) { "#{$1}#{KEEP}" }.gsub(/([.?!][”’")\]]*)\\(?=[[:space:]]|\z)/) { "#{$1}#{BREAK}" }
  end

  def unmark(text) = text.delete(KEEP + BREAK).tr(LITERAL, "\\")

  # Where each marker falls, comparing the split with the markers to the split without them. Positions are counted in
  # characters other than spaces, so the two splits line up.
  def markers(marked, sentences)
    automatic = ends(split(unmark(marked.delete(KEEP + BREAK))))
    actual = ends(sentences)
    found, n = [], 0
    marked.each_char do |ch|
      case ch
      when KEEP then found << { kind: :keep, sentence: actual.count { it < n }, needless: !automatic.include?(n) }
      when BREAK then found << { kind: :break, sentence: actual.count { it < n }, needless: automatic.include?(n) }
      when "\\" then found << { kind: :stray, sentence: actual.count { it <= n } }
      end
      n += 1 unless ch.match?(/[[:space:]]/) || ch == KEEP || ch == BREAK
    end
    found
  end

  def ends(sentences)
    n = 0
    sentences[...-1].map { n += unmark(it).gsub(/[[:space:]]/, "").length }.to_set
  end
end
