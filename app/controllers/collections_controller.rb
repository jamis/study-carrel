class CollectionsController < ApplicationController
  def show
    @collection = Collection.find_by!(slug: params[:slug])
    @works = @collection.works.includes(:sections)
  end
end
