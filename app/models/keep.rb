# Something a reader wants to come back to, whatever their focus. A kept passage is one per (user, unit), with an
# optional short remark; an idea, something to study someday, has no passage and is only its remark.
class Keep < ApplicationRecord
  belongs_to :user
  belongs_to :unit, optional: true

  scope :passages, -> { where.not(unit_id: nil) }
  scope :ideas, -> { where(unit_id: nil) }

  normalizes :remark, with: ->(remark) { remark.strip.presence }
  validates :remark, length: { maximum: 200 }
  validates :remark, presence: true, if: :idea?

  def idea? = unit_id.nil?

  # An idea's first line is its question or topic; the rest, if any, is where to begin, where it came from.
  def idea_title = remark.to_s.lines.first.to_s.strip
  def idea_rest = remark.to_s.lines.drop(1).join.strip.presence

  # Undo puts a keep back where it was in the newest-first list (the time it was kept, from the form); anything else is
  # kept now.
  def self.kept_at(param)
    Time.iso8601(param).clamp(..Time.current) if param
  rescue ArgumentError
    nil
  end
end
