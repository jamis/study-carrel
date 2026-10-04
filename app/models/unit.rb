class Unit < ApplicationRecord
  belongs_to :section
  has_many :notes, dependent: :destroy
  has_many :visits, dependent: :delete_all

  validates :number, presence: true, uniqueness: { scope: :section_id }
  validates :body, presence: true

  def reference = section.reference(number)
end
