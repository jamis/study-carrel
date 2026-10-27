# A user's shelves (see Shelf): the shelf page, and the editor that makes or changes one over the library tree. A shelf
# is also made from "Put on a shelf…" (shelves/_picker), with the one thing it was opened on. Only the owner ever
# reaches a shelf.
class ShelvesController < ApplicationController
  before_action :set_shelf, only: %i[show edit update destroy]

  def show
    @members = @shelf.members
    @work_count = @shelf.work_ids.size
    @work_counts = Collection.work_counts
  end

  def new
    @shelf = Current.user.shelves.new
    load_tree
  end

  def edit
    load_tree
  end

  def create
    @shelf = Current.user.shelves.new(shelf_params)
    return create_from_picker if params[:key]

    if @shelf.save
      @shelf.replace!(ticked)
      redirect_to @shelf
    else
      load_tree
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @shelf.update(shelf_params)
      @shelf.replace!(ticked)
      redirect_to @shelf
    else
      load_tree
      render :edit, status: :unprocessable_content
    end
  end

  # Only the shelf goes: the works stay in the library, and nothing a note or keep hangs off is touched.
  def destroy
    @shelf.destroy!
    redirect_to library_path
  end

  private

  def set_shelf
    @shelf = Current.user.shelves.find_by!(slug: params[:slug])
  end

  def shelf_params = params.expect(shelf: %i[name description])

  # What the editor's boxes name: every ticked one that isn't greyed out under a ticked collection.
  def ticked = Array(params[:items]).filter_map { Shelf.thing_for(it, Current.user) }

  def create_from_picker
    thing = Shelf.thing_for(params[:key], Current.user) or raise ActiveRecord::RecordNotFound
    @shelf.put!(thing) if @shelf.save
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("shelf-picker", partial: "shelves/picker", locals: { thing: }) }
      format.html { redirect_back_or_to @shelf.persisted? ? @shelf : library_path }
    end
  end

  # The library as the editor shows it: collections nested as on their pages (child collections, then works), then
  # works in no collection, then the user's own collections and texts in none, under Your Texts.
  def load_tree
    @collections_by_parent = Collection.visible_to(Current.user).ordered.to_a.group_by(&:parent_id)
    @works_by_collection = Work.visible_to(Current.user).where.not(collection_id: nil).ordered.to_a.group_by(&:collection_id)
    @loose_works = Work.bundled.where(collection_id: nil).ordered.to_a
    @own_collections = Current.user.collections.top_level.to_a
    @texts = Current.user.texts.where(collection_id: nil).to_a
    @work_counts = Collection.work_counts
    @open_ids = @shelf.members.flat_map { @shelf.ancestor_ids(it) }.to_set
  end
end
