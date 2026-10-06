class Unit < ApplicationRecord
  belongs_to :section
  has_many :notes, dependent: :destroy
  has_many :visits, dependent: :delete_all
  has_many :keeps, dependent: :delete_all

  validates :number, presence: true, uniqueness: { scope: :section_id }
  validates :body, presence: true

  # Units of the works a user may see (see Work.visible_to).
  def self.visible_to(user) = joins(section: :work).merge(Work.visible_to(user))

  # How the unit is numbered in a reference: "12:3" (paragraph 12, sentence 3) for a sentence of prose, otherwise
  # its number.
  def label = sentence ? "#{paragraph}:#{sentence}" : number.to_s

  def reference = section.reference(label)

  # Refreshes the full-text index (see LibrarySearch) for the units of the given sections, or of every section.
  def self.reindex_search(section_ids = nil)
    units = section_ids ? where(section_id: section_ids) : all
    transaction do
      connection.exec_delete("DELETE FROM unit_search#{" WHERE rowid IN (#{units.select(:id).to_sql})" if section_ids}")
      connection.exec_insert("INSERT INTO unit_search(rowid, body) #{units.select(:id, :body).to_sql}")
    end
  end

  # Drops units from the full-text index before they are deleted.
  def self.unindex_search(ids)
    connection.exec_delete("DELETE FROM unit_search WHERE rowid IN (#{ids.map(&:to_i).join(",")})") if ids.any?
  end
end
