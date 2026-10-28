module LabelsHelper
  FACE_WORDS = 10

  # A label as it's shown: its name, or for an unnamed one, "group D", the same from every note in it. With snippet, an
  # unnamed one adds the start of the note it's described by (Compare's card, to recall what the group was about).
  def label_face(label, snippet: false, words: FACE_WORDS)
    return tag.span(label.name, class: "lf") if label.named?
    note = label.face_note if snippet
    tag.span(class: "lf lf-unnamed lf-group") do
      safe_join([ tag.span("group", class: "lf-word"), " ", tag.span(label.letter, class: "lf-letter"),
                  (tag.span(" #{face_snippet(note, words)}", class: "lf-snip") if note) ])
    end
  end

  # The same in plain text, for titles and lists: "waiting", or "group D (like Isaiah 40:6: All flesh is grass…)".
  def label_title(label, snippet: true)
    return label.name if label.named?
    note = label.face_note if snippet
    note ? "group #{label.letter} (like #{note_ref(note)}: #{face_snippet(note)})" : "group #{label.letter}"
  end

  # How the reread speaks of the notes on one label: "labelled “waiting”", or "in group D".
  def label_phrase(label) = label.named? ? "labelled “#{label.name}”" : "in #{label_title(label, snippet: false)}"

  # The same, marked so that naming the label redraws it wherever the page says it.
  def label_phrase_tag(label) = tag.span(label_phrase(label), class: dom_id(label, :phrase))

  # Where a note stands: its passage's reference, or for a note on the focus as a whole, its number ("focus 2").
  def note_ref(note) = note.unit ? unit_ref(note.unit.section, note.unit) : "focus #{note.number}"

  # The same, as short as it can be beside another note: "Isaiah 40:6" beside Isaiah 40:7 is just "40:6".
  def short_note_ref(note, from:)
    ref = note_ref(note)
    return ref unless note.unit && from&.unit
    book, rest = ref.rpartition(" ").values_at(0, 2)
    book.present? && book == note_ref(from).rpartition(" ").first ? rest : ref
  end

  def face_snippet(note, words = FACE_WORDS) = note.content.to_plain_text.squish.truncate_words(words, omission: "…")
end
