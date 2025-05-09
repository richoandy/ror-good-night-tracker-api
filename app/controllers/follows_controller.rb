class FollowsController < ApplicationController
  # Create a follow relationship
  def create
    unless User.exists?(follow_params[:follower_id])
      return render json: { error: "Follower user not found" }, status: :unprocessable_entity
    end

    unless User.exists?(follow_params[:following_id])
      return render json: { error: "Following user not found" }, status: :unprocessable_entity
    end

    follow = Follow.new(follow_params)

    if follow.save
      render json: { message: "Followed successfully" }, status: :created
    else
      render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    follow = Follow.find_by(follower_id: params[:id], following_id: params[:following_id])
    if follow
      follow.destroy
      render json: { message: "Unfollowed successfully" }, status: :ok
    else
      render json: { errors: "Follow relationship not found" }, status: :not_found
    end
  end

  private

  def follow_params
    params.require(:follow).permit(:follower_id, :following_id)
  end
end
