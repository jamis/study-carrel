class LibraryController < ApplicationController
  def index
    @collections = Collection.bundled.top_level.ordered
    @loose_works = Work.bundled.where(collection_id: nil).ordered
    @texts = Current.user.texts
    @shelves = Current.user.shelves.to_a
    @own_collections = Current.user.collections.top_level.to_a
    @work_counts = Collection.bundled.work_counts
  end
end
