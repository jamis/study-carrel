# A collection's page, the library's or the user's own. A user's own collection is made empty, filled by adding texts
# into it (see UserTextsController), and deleted with its texts after a page saying what goes with it. Only the owner
# ever reaches one.
class CollectionsController < ApplicationController
  include SetsAsideNotes

  before_action :set_own_collection, only: %i[delete destroy]

  def show
    @collection = Collection.visible_to(Current.user).find_by!(slug: params[:slug])
    @children = @collection.children
    @works = @collection.works.includes(:sections)
    @work_counts = Collection.work_counts
  end

  def new
    @collection = Current.user.collections.new
  end

  def create
    @collection = Current.user.collections.new(params.expect(collection: %i[name description single_work]))
    if @collection.save
      redirect_to @collection, notice: "Made “#{@collection.name}”."
    else
      render :new, status: :unprocessable_content
    end
  end

  # What deleting it takes: its texts, and the notes and keeps on them, which are set aside.
  def delete
    @works = @collection.all_works.order(:title, :id).to_a
    units = Unit.joins(:section).where(sections: { work_id: @works })
    @annotation_count = Note.where(unit_id: units.select(:id)).count + Keep.where(unit_id: units.select(:id)).count
  end

  def destroy
    count = @collection.all_works.count
    detached = set_aside_count { @collection.remove! }
    texts = " and #{count == 1 ? "its text" : "its #{count} texts"}" if count.positive?
    redirect_to texts_path, notice: "Deleted “#{@collection.name}”#{texts}.#{set_aside_message(detached)}"
  end

  private

  def set_own_collection = @collection = Current.user.collections.find_by!(slug: params[:slug])
end
