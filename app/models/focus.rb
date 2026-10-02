class Focus < ApplicationRecord
  validates :title, presence: true

  scope :current, -> { where(archived_at: nil) }

  def self.current_one = current.order(:created_at).last

  scope :past, -> { where.not(archived_at: nil).order(archived_at: :desc) }

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
