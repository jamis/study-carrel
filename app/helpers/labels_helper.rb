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
      safe_join([ tag.span("like #{note_ref(note)}", class: "lf-like"), tag.span(" #{face_snippet(note, words)}", class: "lf-snip") ])
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

  # Where a note stands: its passage's reference, or the focus as a whole.
  def note_ref(note) = note.unit ? unit_ref(note.unit.section, note.unit) : "a note on the whole focus"

  def face_snippet(note, words = FACE_WORDS) = note.content.to_plain_text.squish.truncate_words(words, omission: "…")
end
