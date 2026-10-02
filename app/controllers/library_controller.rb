class LibraryController < ApplicationController
  def index
    @collections = Collection.ordered.includes(:works)
    @loose_works = Work.where(collection_id: nil).ordered
  end
end
