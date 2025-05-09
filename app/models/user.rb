class User < ApplicationRecord
  # User A following list
  has_many :follows, foreign_key: :follower_id, dependent: :destroy
  has_many :followings, through: :follows, source: :following

  # User A follower list
  has_many :reverse_follows, class_name: "Follow", foreign_key: :following_id, dependent: :destroy
  has_many :followers, through: :reverse_follows, source: :follower
end
