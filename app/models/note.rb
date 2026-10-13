class Note < ApplicationRecord
  belongs_to :unit
  belongs_to :focus

  has_many :note_labels, dependent: :destroy
  has_many :labels, through: :note_labels

  has_rich_text :content

  validates :content, presence: true
  validates :unit_id, uniqueness: { scope: :focus_id }

  scope :chronological, -> { order(:created_at, :id) }

  # Puts the note on its owner's label of that name (found ignoring case, or made), and returns the label.
  def label!(name)
    transaction do
      label = focus.user.labels.find_or_create_by!(name: Label.normalize_value_for(:name, name))
      note_labels.find_or_create_by!(label:)
      label
    end
  end

  def unlabel!(label) = note_labels.find_by(label:)&.destroy!
end
