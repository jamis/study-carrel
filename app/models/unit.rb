class Unit < ApplicationRecord
  belongs_to :section
  has_many :notes, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :section_id }
  validates :body, presence: true
end
