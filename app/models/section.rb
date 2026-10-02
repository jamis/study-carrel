class Section < ApplicationRecord
  belongs_to :work
  has_many :units, -> { order(:number) }, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :work_id }

  def name = "#{work.title} #{label.presence || number}"
end
