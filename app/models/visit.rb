# Where a user has been reading, across every focus: one row per unit, most recent first.
class Visit < ApplicationRecord
  LIMIT = 50

  belongs_to :user
  belongs_to :unit

  scope :recent, -> { order(visited_at: :desc, id: :desc) }

  # Stepping to a neighboring unit moves the latest entry along instead of adding one, so the list holds
  # places (a random hop, a jump to another chapter) rather than every verse read on the way.
  def self.record(user, unit)
    transaction do
      latest = user.visits.recent.includes(:unit).first
      latest.destroy if latest && latest.neighbor_of?(unit)
      upsert({ user_id: user.id, unit_id: unit.id, visited_at: Time.current }, unique_by: %i[user_id unit_id])
      user.visits.recent.offset(LIMIT).destroy_all
    end
  end

  def neighbor_of?(other)
    unit.section_id == other.section_id && (unit.number - other.number).abs == 1
  end
end
