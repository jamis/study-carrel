module LabelsHelper
  FACE_WORDS = 10

  # A label as it's shown: its name, or for an unnamed one, "like Isaiah 40:6" and the start of that note (the snippet
  # in its own span, which CSS hides where there's no room). from: the note it's seen from, which an unnamed label
  # isn't shown "like".
  def label_face(label, from: nil, words: FACE_WORDS)
    return tag.span(label.name, class: "lf") if label.named?
    note = label.face_note(from:)
    return tag.span("just this note, so far", class: "lf lf-unnamed") unless note
    tag.span(class: "lf lf-unnamed") do
      safe_join([ tag.span(safe_join([ "like ", condensed_ref(note_ref(note)) ]), class: "lf-like"), tag.span(" #{face_snippet(note, words)}", class: "lf-snip") ])
    end
  end

  # The same in plain text, for titles and lists: "waiting", or "like Isaiah 40:6: All flesh is grass…".
  def label_title(label, from: nil, snippet: true)
    return label.name if label.named?
    note = label.face_note(from:)
    return "just this note, so far" unless note
    snippet ? "like #{note_ref(note)}: #{face_snippet(note)}" : "like #{note_ref(note)}"
  end

  # How the reread speaks of the notes on one label: "labelled “waiting”", or "in the group like Isaiah 40:6".
  def label_phrase(label) = label.named? ? "labelled “#{label.name}”" : "in the group #{label_title(label, snippet: false)}"

  # Where a note stands: its passage's reference, or for a note on the focus as a whole, its number ("focus 2").
  def note_ref(note) = note.unit ? unit_ref(note.unit.section, note.unit) : "focus #{note.number}"

  # The same, as short as it can be beside another note: "Isaiah 40:6" beside Isaiah 40:7 is just "40:6".
  def short_note_ref(note, from:)
    ref = note_ref(note)
    return ref unless note.unit && from&.unit
    book, rest = ref.rpartition(" ").values_at(0, 2)
    book.present? && book == note_ref(from).rpartition(" ").first ? rest : ref
  end

  # A reference where room is short (footnotes): a long title or name, which CSS cuts short, and its last part ("1:6"),
  # which tells it from its neighbours and is never cut. A short one ("Isaiah 40:6", "focus 2") is left as it is.
  def condensed_ref(ref)
    name, _, at = ref.rpartition(" ")
    return ref if name.length <= 12
    safe_join([ tag.span(name, class: "ref-name"), tag.span(at, class: "ref-at") ], " ")
  end

  # Each label's notes on a focus, keyed by label id, in the order given (the reread's): what a note's footnotes name.
  # notes: the focus's notes, with their labels.
  def label_members(notes)
    notes.flat_map { |note| note.label_ids.map { [ it, note ] } }.group_by(&:first).transform_values { it.map(&:last) }
  end

  # A note's labels in the order they were made, so a label keeps its footnote number as notes come and go.
  def footnoted_labels(note) = note.labels.sort_by(&:id)

  def face_snippet(note, words = FACE_WORDS) = note.content.to_plain_text.squish.truncate_words(words, omission: "…")
end
