class Unit < ApplicationRecord
  belongs_to :section
  has_many :notes, dependent: :destroy
  has_many :visits, dependent: :delete_all
  has_many :keeps, dependent: :delete_all

  validates :number, presence: true, uniqueness: { scope: :section_id }
  validates :body, presence: true

  def reference = section.reference(number)

  # Refreshes the full-text index (see LibrarySearch) for the units of the given sections, or of every section.
  def self.reindex_search(section_ids = nil)
    units = section_ids ? where(section_id: section_ids) : all
    transaction do
      connection.exec_delete("DELETE FROM unit_search#{" WHERE rowid IN (#{units.select(:id).to_sql})" if section_ids}")
      connection.exec_insert("INSERT INTO unit_search(rowid, body) #{units.select(:id, :body).to_sql}")
    end
  end
end
