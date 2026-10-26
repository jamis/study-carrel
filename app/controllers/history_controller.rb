# The recent-places dropdown in the rail: the newest places first, the one on screen included. It needs no focus (none
# is current after archiving the current one); without one, nothing is marked as noted.
class HistoryController < ApplicationController
  SHOWN = 8

  def index
    @visits = Current.user.visits.recent.limit(SHOWN).includes(unit: { section: :work })
    unit_ids = @visits.map(&:unit_id)
    @noted_unit_ids = Current.focus ? Current.focus.notes.where(unit_id: unit_ids).pluck(:unit_id).to_set : Set.new
    @kept_unit_ids = Current.user.keeps.where(unit_id: unit_ids).pluck(:unit_id).to_set
    render layout: false
  end
end
