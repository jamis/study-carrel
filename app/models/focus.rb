class Focus < ApplicationRecord
  validates :title, presence: true

  scope :current, -> { where(archived_at: nil) }

  def self.current_one = current.order(:created_at).last

  # Only one focus is current at a time: starting a new one archives the old.
  def self.start!(attrs)
    transaction do
      current.update_all(archived_at: Time.current)
      create!(attrs)
    end
  end
end
