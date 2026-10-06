class Section < ApplicationRecord
  belongs_to :work
  has_many :units, -> { order(:number) }, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :work_id }

  # Reading continues from the end of one section into the next, and from one book into the next.
  def next_section = work.sections.where("number > ?", number).first || work.next_work&.sections&.first
  def previous_section = work.sections.where("number < ?", number).last || work.previous_work&.sections&.last

  # Chapters are numbered ("Isaiah 40"); other texts name their sections ("Walden: Economy").
  # A user's text with no headings is one unnamed section, cited by the work alone ("Journal 3:2").
  def name
    return work.title if label.blank? && work.own_text?

    numbered? ? "#{work.title} #{display_label}" : "#{work.title}: #{display_label}"
  end

  # How to cite a unit, with a placeholder the browser can fill (with Unit#label) as the reader moves: "Isaiah 40:3",
  # "Emily Dickinson: Success, stanza 2", or for a sentence of prose "Walden: Economy 12:3".
  def reference_template = "#{name}#{reference_unit_template}"
  def reference(label) = reference_template.sub("{n}", label.to_s)

  # The reference's leading part split in two: the work title (which the panel may drop when space is short) and the
  # section name. Numbered chapters have no separable title ("Isaiah 40").
  def reference_name_parts = numbered? ? [ "", name ] : [ "#{work.title}: ", display_label ]

  # The same reference in parts, so a long name can truncate while the unit number stays visible. A user's poem with no
  # headings is cited by the work alone, so its stanzas are named ("Low Water, stanza 2"), not numbered.
  def reference_unit_template = work.sentences? ? " {n}" : numbered? && !unnamed? ? ":{n}" : ", #{work.unit_name} {n}"

  def numbered? = display_label.match?(/\A\d+\z/)

  private

  def display_label = label.presence || number.to_s

  def unnamed? = label.blank? && work.own_text?
end
