# A label a user puts on notes while rereading a focus, to sort them like index cards into piles. It belongs to the
# user, not to a focus, so the same label can gather notes from several focuses; it's only ever found through
# user.labels. Names are unique per user, ignoring case. A label lasts only while some note carries it.
#
# A label needn't have a name: notes found to go together (in the reread's "Find what goes with this") make a group
# before there are words for it. An unnamed label is known by one of its notes, its example; naming it later makes it
# an ordinary label.
class Label < ApplicationRecord
  belongs_to :user
  belongs_to :example_note, class_name: "Note", optional: true
  has_many :note_labels, dependent: :delete_all
  has_many :notes, through: :note_labels

  normalizes :name, with: ->(name) { name.squish.presence }
  validates :name, presence: true, unless: :example_note_id?
  validates :name, length: { maximum: 40 }, uniqueness: { scope: :user_id, case_sensitive: false }, allow_nil: true

  # What showing a label needs: an unnamed one is shown by its example note's reference and words.
  FACE = { example_note: [ :rich_text_content, { unit: { section: :work } } ] }.freeze

  scope :unused, -> { where.missing(:note_labels) }
  # Named labels A–Z, then unnamed ones in the order they were made.
  scope :alphabetical, -> { order(Arel.sql("labels.name IS NULL"), Arel.sql("labels.name COLLATE NOCASE"), :id) }

  # When each label was last put on a note, keyed by label id (the picker's Recent order).
  def self.last_used = NoteLabel.where(label_id: select(:id)).group(:label_id).maximum(:created_at)

  def named? = name.present?

  # A colour of its own among six, kept for as long as the label lasts.
  def hue = id % 6

  # The note an unnamed label is known by: its example, or when that's the note you're looking from (where "like this
  # note" says nothing) or it has gone, the next of its notes, in the order they were put on it. Nil when the note
  # you're looking from is alone in it.
  def face_note(from: nil)
    return example_note if example_note && example_note != from
    note_labels.where.not(note_id: from).order(:created_at, :id).first&.note
  end

  # Gives it words, or (blank) takes them away again, leaving it known by its example. A name it shares with another
  # of the user's labels is refused: the two aren't merged.
  def rename!(new_name)
    self.name = new_name
    self.example_note ||= note_labels.order(:created_at, :id).first&.note unless named?
    save!
  end
end
