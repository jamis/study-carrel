# A single-use link that lets one person sign up. Whoever holds the link can use it, so it is
# stored only as a digest: the token itself is shown once, when the admin creates it.
class Invitation < ApplicationRecord
  EXPIRES_IN = 7.days

  belongs_to :created_by, class_name: "User"
  belongs_to :redeemed_by, class_name: "User", optional: true

  attr_reader :token

  before_validation :generate_token, on: :create
  validates :token_digest, :expires_at, presence: true

  scope :pending, -> { where(redeemed_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.digest(token) = Digest::SHA256.hexdigest(token.to_s)
  def self.find_redeemable(token) = pending.find_by(token_digest: digest(token))

  def status
    if redeemed_at then :used
    elsif revoked_at then :revoked
    elsif expires_at <= Time.current then :expired
    else :pending
    end
  end

  def pending? = status == :pending
  def revoke! = pending? && update!(revoked_at: Time.current)

  # Signs someone up with this invitation. The claim is one atomic UPDATE, so two people using the
  # link at the same moment can't both get in; if the sign-up is invalid the claim is rolled back.
  # Returns the user, persisted or carrying errors.
  def redeem(attributes)
    user = User.new(attributes)
    transaction do
      if self.class.pending.where(id: id).update_all(redeemed_at: Time.current) == 0
        user.errors.add(:base, "This invitation has already been used.")
        raise ActiveRecord::Rollback
      end
      raise ActiveRecord::Rollback unless user.save

      update_columns(redeemed_by_id: user.id)
    end
    user
  end

  private

  def generate_token
    return if token_digest.present?

    @token = SecureRandom.urlsafe_base64(24)
    self.token_digest = self.class.digest(@token)
    self.expires_at ||= EXPIRES_IN.from_now
  end
end
