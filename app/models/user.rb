class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :foci, dependent: :destroy do
    # Defined on the association, not on Focus, so they can only ever see this user's foci.
    def current_one = current.order(:created_at).last

    # Only one focus is current at a time: starting one archives the old one.
    def start!(attrs)
      transaction do
        proxy_association.owner.foci.current.update_all(archived_at: Time.current)
        create!(attrs)
      end
    end
  end
  has_many :visits, dependent: :delete_all
  has_many :keeps, dependent: :delete_all
  has_many :detached_notes, -> { ordered }, dependent: :destroy
  has_many :texts, -> { order(:title, :id) }, class_name: "Work", inverse_of: :user
  has_many :invitations, foreign_key: :created_by_id, inverse_of: :created_by, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
end
