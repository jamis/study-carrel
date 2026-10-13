class LibraryController < ApplicationController
  def index
    @collections = Collection.top_level.ordered
    @loose_works = Work.bundled.where(collection_id: nil).ordered
    @texts = Current.user.texts
    @shelves = Current.user.shelves.to_a
    @work_counts = Collection.work_counts
  end
end
