class LibraryController < ApplicationController
  def index
    @collections = Collection.top_level.ordered
    @loose_works = Work.where(collection_id: nil).ordered
  end
end
