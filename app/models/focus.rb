class Focus < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  has_many :detached_notes, -> { ordered }, dependent: :nullify
  belongs_to :last_unit, class_name: "Unit", optional: true
  belongs_to :reread_note, class_name: "Note", optional: true

  # Rough thoughts while rereading this focus's notes.
  has_rich_text :scratchpad

  validates :title, presence: true

  # user.foci.current_one and user.foci.start! are defined on the association in User.
  scope :current, -> { where(archived_at: nil) }

  scope :past, -> { where.not(archived_at: nil).order(archived_at: :desc) }

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
  def free_notes = notes.free.includes(:rich_text_content, :labels).chronological

  # The run the reread goes through: the notes on passages in reading order, then those on the focus as a whole.
  def notes_for_reread = notes_in_reading_order.includes(:labels).to_a + free_notes.to_a

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

  def archived? = archived_at.present?
  def archive! = update!(archived_at: Time.current)

  # Bring a past focus back; whatever else is current for this user moves to the archive.
  def restore!
    self.class.transaction do
      user.foci.current.where.not(id: id).update_all(archived_at: Time.current)
      update!(archived_at: nil)
    end
  end
end
