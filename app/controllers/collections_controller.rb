class CollectionsController < ApplicationController
  def show
    @collection = Collection.find_by!(slug: params[:slug])
    @children = @collection.children
    @works = @collection.works.includes(:sections)
    @work_counts = Collection.work_counts
  end
end
