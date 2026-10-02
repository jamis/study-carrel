# Remembers where the reader is in the current focus, so the app reopens there.
class PositionsController < ApplicationController
  def update
    focus = Current.user.foci.current_one or return head(:no_content)
    focus.update!(last_unit: Unit.find(params.expect(:unit_id)))
    head :no_content
  end
end
