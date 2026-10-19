# A label on a note. Taking off a label's last note drops the label; taking off its example moves the example on to
# the next of its notes.
class NoteLabel < ApplicationRecord
  belongs_to :note
  belongs_to :label

  validates :label_id, uniqueness: { scope: :note_id }
  validate :same_owner

  after_destroy do
    if !label.note_labels.exists? then label.destroy
    elsif label.example_note_id == note_id then label.update!(example_note: label.note_labels.order(:created_at, :id).first.note)
    end
  end

  private

  def same_owner
    errors.add(:label, "is someone else's") if note && label && note.focus.user_id != label.user_id
  end
end
