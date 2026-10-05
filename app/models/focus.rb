class Focus < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  belongs_to :last_unit, class_name: "Unit", optional: true

  validates :title, presence: true

  # user.foci.current_one and user.foci.start! are defined on the association in User.
  scope :current, -> { where(archived_at: nil) }

  scope :past, -> { where.not(archived_at: nil).order(archived_at: :desc) }

  def notes_in_reading_order
    notes.includes(:rich_text_content, unit: { section: :work })
         .joins(unit: { section: :work })
         .order("works.position", "works.id", "sections.number", "units.number", :created_at, :id)
  end

  def archived? = archived_at.present?
  def archive! = update!(archived_at: Time.current)

  # Bring a past focus back; whatever else is current for this user moves to the archive.
  def restore!
    self.class.transaction do
      user.foci.current.where.not(id: id).update_all(archived_at: Time.current)
      update!(archived_at: nil)
    end
  end
end
