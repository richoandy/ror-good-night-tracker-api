class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :following, class_name: "User"

  validates :follower_id, uniqueness: { scope: :following_id, message: "already follows this user" }
  validate :same_follower_and_following_id

  private

  def same_follower_and_following_id
    if follower_id == following_id
      errors.add(:following_id, "cannot be the same as follower")
    end
  end
end
