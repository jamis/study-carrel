# One work or one collection on a shelf (see Shelf).
class ShelfItem < ApplicationRecord
  belongs_to :shelf
  belongs_to :work, optional: true
  belongs_to :collection, optional: true

  def thing = work || collection
end
