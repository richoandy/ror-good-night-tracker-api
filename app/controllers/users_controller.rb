class UsersController < ApplicationController
  before_action :validate_user_exists, only: [ :followers, :following ]

  def create
    user = User.new(user_params)

    if user.save
      render json: user.as_json
    else
      render json: { message: "User creation failed", errors: user.errors.full_messages }
    end
  end

  def followers
    user = User.find(params[:id])
    followers = user.followers

    render json: {
      user_id: user.id,
      followers: followers
    }, status: :ok
  end

  def following
    user = User.find(params[:id])
    following = user.followings

    render json: {
      user_id: user.id,
      following: following
    }, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end

  def validate_user_exists
    unless User.exists?(params[:id])
      render json: { error: "User not found" }, status: :not_found
    end
  end
end
