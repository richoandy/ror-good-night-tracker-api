class TimeClocking < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
  validates :clock_in, presence: true
end
