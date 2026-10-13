# A label a user puts on notes while rereading a focus, to sort them like index cards into piles. It belongs to the
# user, not to a focus, so the same label can gather notes from several focuses; it's only ever found through
# user.labels. Names are unique per user, ignoring case. A label lasts only while some note carries it.
class Label < ApplicationRecord
  belongs_to :user
  has_many :note_labels, dependent: :delete_all
  has_many :notes, through: :note_labels

  normalizes :name, with: ->(name) { name.squish }
  validates :name, presence: true, length: { maximum: 40 }, uniqueness: { scope: :user_id, case_sensitive: false }

  scope :unused, -> { where.missing(:note_labels) }
  scope :alphabetical, -> { order(Arel.sql("name COLLATE NOCASE"), :id) }
end
