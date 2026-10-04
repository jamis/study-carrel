# A passage a reader wants to come back to, whatever their focus: one per (user, unit), with an optional short remark.
class Keep < ApplicationRecord
  belongs_to :user
  belongs_to :unit

  normalizes :remark, with: ->(remark) { remark.strip.presence }
  validates :remark, length: { maximum: 200 }
end
