# A label on a note. Taking off a label's last note drops the label.
class NoteLabel < ApplicationRecord
  belongs_to :note
  belongs_to :label

  validates :label_id, uniqueness: { scope: :note_id }
  validate :same_owner

  after_destroy { label.destroy unless label.note_labels.exists? }

  private

  def same_owner
    errors.add(:label, "is someone else's") if note && label && note.focus.user_id != label.user_id
  end
end
