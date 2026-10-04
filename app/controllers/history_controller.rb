# The recent-places dropdown in the reading nav. The newest visit is the place you're reading now, so it's left out.
class HistoryController < ApplicationController
  include RequiresFocus

  SHOWN = 8

  def index
    @visits = Current.user.visits.recent.offset(1).limit(SHOWN).includes(unit: { section: :work })
    @noted_unit_ids = @focus.notes.where(unit_id: @visits.map(&:unit_id)).pluck(:unit_id).to_set
    render layout: false
  end
end
