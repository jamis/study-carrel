class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :foci, dependent: :destroy do
    # Defined on the association, not on Focus, so they can only ever see this user's foci.
    # The focus most recently made current, unless it has been archived since: then none is.
    def current_one = by_recency.first&.then { it unless it.archived? }

    # Every focus not archived but the current one, most recently current first.
    def others = active.by_recency.where.not(id: current_one&.id)

    # A new focus is current; the old one stays among the others.
    def start!(attrs) = create!(attrs)
  end
  has_many :visits, dependent: :delete_all
  has_many :keeps, dependent: :delete_all
  has_many :detached_notes, -> { ordered }, dependent: :destroy
  has_many :texts, -> { order(:title, :id) }, class_name: "Work", inverse_of: :user
  has_many :collections, -> { order(:name, :id) }, inverse_of: :user
  has_many :shelves, -> { order(:name, :id) }, dependent: :destroy
  has_many :labels, dependent: :delete_all
  has_many :invitations, foreign_key: :created_by_id, inverse_of: :created_by, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
end
