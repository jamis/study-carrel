class Note < ApplicationRecord
  # A free note has no unit: it's on the focus as a whole, not on a passage.
  belongs_to :unit, optional: true
  belongs_to :focus

  has_many :note_labels, dependent: :destroy
  has_many :labels, through: :note_labels

  has_rich_text :content

  validates :content, presence: true
  validates :unit_id, uniqueness: { scope: :focus_id }, allow_nil: true

  scope :chronological, -> { order(:created_at, :id) }
  scope :free, -> { where(unit_id: nil) }

  def free? = unit_id.nil?

  # Puts the note on its owner's label of that name (found ignoring case, or made), and returns the label. A blank name
  # is refused.
  def label!(name)
    name = Label.normalize_value_for(:name, name)
    transaction do
      label = name ? focus.user.labels.find_or_create_by!(name:) : focus.user.labels.create!(name:)
      note_labels.find_or_create_by!(label:)
      label
    end
  end

  # Puts the note on one of its owner's labels, named or not.
  def join!(label)
    note_labels.find_or_create_by!(label:)
    label
  end

  # A new unnamed label holding this note and another found to go with it, known by this one.
  def group_with!(other)
    transaction do
      label = focus.user.labels.create!(example_note: self)
      note_labels.create!(label:)
      other.note_labels.create!(label:)
      label
    end
  end

  def unlabel!(label) = note_labels.find_by(label:)&.destroy!
end
