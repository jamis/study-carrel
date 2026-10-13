# "Put on a shelf…" on a work or collection page: ticking a shelf puts the thing on it, unticking takes it off, and the
# picker is drawn again (see Shelf#put! for what putting a collection on takes in).
class ShelfItemsController < ApplicationController
  def create
    shelf.put!(thing)
    redraw
  end

  def destroy
    shelf.take!(thing)
    redraw
  end

  private

  def shelf = @shelf ||= Current.user.shelves.find_by!(slug: params[:shelf_slug])
  def thing = @thing ||= Shelf.thing_for(params[:key], Current.user) || raise(ActiveRecord::RecordNotFound)

  def redraw
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("shelf-picker", partial: "shelves/picker", locals: { thing: }) }
      format.html { redirect_back_or_to shelf }
    end
  end
end
