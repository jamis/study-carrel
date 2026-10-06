# A note, or a kept passage's remark, set aside because its passage is gone: the user revised their own text and the
# sentence no longer exists, or deleted the text. It keeps a frozen copy of the citation and the passage, its original
# times, and its focus (none for a kept remark, which belongs to no focus). Nothing is lost when a text changes.
class DetachedNote < ApplicationRecord
  REASONS = { "revised" => "the text was revised", "deleted" => "the text was deleted" }.freeze

  belongs_to :user
  belongs_to :focus, optional: true

  has_rich_text :content

  validates :reason, inclusion: { in: REASONS.keys }

  scope :ordered, -> { order(:created_at, :id) }

  # Sets aside every note and remarked keep on the given units, before the units are changed or deleted: a note's rich
  # text moves to its detached note rather than being copied. Keeps without a remark are dropped, as are visits, and a
  # focus whose place was one of them forgets it. The units themselves are left to the caller.
  def self.set_aside!(units, reason:)
    units = units.includes(section: :work).index_by(&:id)
    transaction do
      Note.where(unit_id: units.keys).includes(:focus, :rich_text_content).find_each do |note|
        detached = create!(user: note.focus.user, focus: note.focus, **frozen(units[note.unit_id], reason, note))
        note.rich_text_content&.update_columns(record_type: name, record_id: detached.id)
        Note.where(id: note.id).delete_all
      end
      Keep.where(unit_id: units.keys).find_each do |keep|
        create!(user: keep.user, kept: true, content: "<p>#{ERB::Util.html_escape(keep.remark)}</p>", **frozen(units[keep.unit_id], reason, keep)) if keep.remark
        keep.delete
      end
      Visit.where(unit_id: units.keys).delete_all
      Focus.where(last_unit_id: units.keys).update_all(last_unit_id: nil)
    end
  end

  def self.frozen(unit, reason, record)
    { citation: unit.reference, work_title: unit.section.work.title, passage: unit.body, reason:,
      noted_at: record.created_at, edited_at: record.updated_at }
  end
  private_class_method :frozen

  def why = REASONS.fetch(reason)
end
