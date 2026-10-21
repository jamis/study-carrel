# The reader's picker, under the focus: the reader's other focuses, to write this passage's note under one without
# making it current. Those with a note on the passage come first, then the rest, most recently current first. Archived
# foci aren't among them.
class UnitFociController < ApplicationController
  include RequiresFocus

  def index
    unit = Unit.visible_to(Current.user).find(params[:unit_id])
    others = Current.user.foci.others.to_a
    noted = Note.where(focus: others, unit: unit).pluck(:focus_id).to_set
    @foci = others.partition { noted.include?(it.id) }.flatten
    @noted = noted
    @unit = unit
  end
end
