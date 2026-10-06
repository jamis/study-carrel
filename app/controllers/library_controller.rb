class LibraryController < ApplicationController
  def index
    @collections = Collection.top_level.ordered
    @loose_works = Work.bundled.where(collection_id: nil).ordered
    @texts = Current.user.texts
    @work_counts = Collection.work_counts
  end
end
