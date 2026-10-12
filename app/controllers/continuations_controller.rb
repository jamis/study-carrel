# "Continue reading": back to where the current focus left off.
class ContinuationsController < ApplicationController
  include RequiresFocus

  def show
    if (unit = @focus.last_unit)
      redirect_to reading_path(unit.section.work.slug, unit.section.number, unit.number)
    else
      # Nothing read yet under this focus: let them choose where to begin.
      redirect_to library_path
    end
  end
end
