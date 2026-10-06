# Remembers where the reader is, so the app reopens there: the place in the current focus, and the user's history.
class PositionsController < ApplicationController
  def update
    unit = Unit.visible_to(Current.user).find(params.expect(:unit_id))
    Visit.record(Current.user, unit)
    Current.focus&.update!(last_unit: unit)
    head :no_content
  end
end
