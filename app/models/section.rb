class Section < ApplicationRecord
  belongs_to :work
  has_many :units, -> { order(:number) }, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :work_id }

  # Reading continues from the end of one section into the next, and from one book into the next.
  def next_section = work.sections.where("number > ?", number).first || work.next_work&.sections&.first
  def previous_section = work.sections.where("number < ?", number).last || work.previous_work&.sections&.last

  # Chapters are numbered ("Isaiah 40"); other texts name their sections ("Walden: Economy").
  def name = numbered? ? "#{work.title} #{display_label}" : "#{work.title}: #{display_label}"

  # How to cite a unit, with a placeholder the browser can fill as the reader moves.
  def reference_template = numbered? ? "#{name}:{n}" : "#{name}, #{work.unit_name} {n}"
  def reference(number) = reference_template.sub("{n}", number.to_s)

  def numbered? = display_label.match?(/\A\d+\z/)

  private

  def display_label = label.presence || number.to_s
end
