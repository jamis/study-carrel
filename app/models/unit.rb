class Unit < ApplicationRecord
  belongs_to :section

  validates :number, presence: true, uniqueness: { scope: :section_id }
  validates :body, presence: true
end
