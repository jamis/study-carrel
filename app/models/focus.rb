class Focus < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  # Deleting a focus deletes everything written under it. Its notes take their labels with them where no other note
  # carries them (a label lasts only while some note does).
  has_many :detached_notes, -> { ordered }, dependent: :destroy
  belongs_to :last_unit, class_name: "Unit", optional: true
  belongs_to :reread_note, class_name: "Note", optional: true

  # Rough thoughts while rereading this focus's notes.
  has_rich_text :scratchpad

  validates :title, presence: true

  # The latest of a user's is the current focus (user.foci.current_one, with start! and the others, is defined on the
  # association in User). Making one current stamps it; nothing else changes.
  attribute :made_current_at, default: -> { Time.current }

  # Archived foci are put away: off the focuses page, their notes read-only.
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil).order(archived_at: :desc, id: :desc) }
  scope :by_recency, -> { order(made_current_at: :desc, id: :desc) }

  # For the focuses page, called on a set of foci (user.foci): a query apiece, keyed by focus id.
  def self.note_counts = Note.where(focus_id: select(:id)).group(:focus_id).count

  # The titles of the works each focus has notes in, in library order.
  def self.works_read
    Work.joins(sections: { units: :notes }).where(notes: { focus_id: select(:id) })
        .group("notes.focus_id", "works.id").order("works.position", "works.id")
        .pluck("notes.focus_id", "works.title")
        .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
  end

  # Notes on the focus as a whole, in the order they were written. (notes_in_reading_order has only those on passages.)
  def free_notes = notes.free.includes(:rich_text_content, labels: Label::FACE).chronological

  # The run the reread goes through: the notes on passages in reading order, then those on the focus as a whole.
  def notes_for_reread = notes_in_reading_order.includes(labels: Label::FACE).to_a + free_notes.to_a

  def notes_in_reading_order
    notes.includes(:rich_text_content, unit: { section: :work })
         .joins(unit: { section: :work })
         .order("works.position", "works.id", "sections.number", "units.number", :created_at, :id)
  end

  # How many of this focus's notes carry each label, keyed by label id.
  def label_counts = NoteLabel.joins(:note).where(notes: { focus_id: id }).group(:label_id).count

  # The titles of the user's other focuses each label is used under, keyed by label id.
  def labels_elsewhere
    NoteLabel.joins(note: :focus).where(foci: { user_id: user_id }).where.not(notes: { focus_id: id })
             .distinct.order("foci.created_at").pluck(:label_id, "foci.title")
             .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
  end

  def make_current! = update!(made_current_at: Time.current)

  # Archiving the current focus leaves none current until another is chosen. Unarchived, a focus is current again only
  # if none was made current since (so undoing the archiving of the current focus puts it back as it was).
  def archived? = archived_at.present?
  def archive! = update!(archived_at: Time.current)
  def unarchive! = update!(archived_at: nil)
end
