class Session < ApplicationRecord
  MAX_AGE = 30.days

  belongs_to :user

  scope :active,  -> { where(created_at: MAX_AGE.ago..) }
  scope :expired, -> { where(created_at: ...MAX_AGE.ago) }
end
