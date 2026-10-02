class Focus < ApplicationRecord
  has_many :notes, dependent: :destroy
  belongs_to :last_unit, class_name: "Unit", optional: true

  validates :title, presence: true

  scope :current, -> { where(archived_at: nil) }

  def self.current_one = current.order(:created_at).last

  scope :past, -> { where.not(archived_at: nil).order(archived_at: :desc) }

  def notes_in_reading_order
    notes.includes(:rich_text_content, unit: { section: :work })
         .joins(unit: { section: :work })
         .order("works.id", "sections.number", "units.number", :created_at, :id)
  end

  def archived? = archived_at.present?
  def archive! = update!(archived_at: Time.current)

  # Bring a past focus back; whatever is current moves to the archive.
  def restore!
    self.class.transaction do
      self.class.current.where.not(id: id).update_all(archived_at: Time.current)
      update!(archived_at: nil)
    end
  end

  # Only one focus is current at a time: starting a new one archives the old.
  def self.start!(attrs)
    transaction do
      current.update_all(archived_at: Time.current)
      create!(attrs)
    end
  end
end
