class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :foci, dependent: :destroy
  has_many :invitations, foreign_key: :created_by_id, inverse_of: :created_by, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
end
