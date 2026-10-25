# The recent-places dropdown in the rail: the newest places first, the one on screen included.
class HistoryController < ApplicationController
  include RequiresFocus

  SHOWN = 8

  def index
    @visits = Current.user.visits.recent.limit(SHOWN).includes(unit: { section: :work })
    @noted_unit_ids = @focus.notes.where(unit_id: @visits.map(&:unit_id)).pluck(:unit_id).to_set
    @kept_unit_ids = Current.user.keeps.where(unit_id: @visits.map(&:unit_id)).pluck(:unit_id).to_set
    render layout: false
  end
end
