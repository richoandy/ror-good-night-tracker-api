class FollowsController < ApplicationController
  # Create a follow relationship
  def create
    follower = User.find_by(id: follow_params[:follower_id])
    if follower.nil?
      render json: { error: "Follower user not found" }, status: :unprocessable_entity
      return
    end

    following = User.find_by(id: follow_params[:following_id])
    if following.nil?
      render json: { error: "Following user not found" }, status: :unprocessable_entity
      return
    end

    follow = Follow.new(follow_params)

    if follow.save
      # Update Redis cache for new follower's time-clocking data
      Rails.logger.debug "! setting up new cache feed for user #{follow.follower_id} to following user:#{follow.following_id}"

      FollowingCacheJob.perform_async(follow.follower_id, follow.following_id)

      render json: { message: "Followed successfully" }, status: :created
    else
      render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    follow = Follow.find_by(follower_id: params[:id], following_id: params[:following_id])
    if follow
      follow.destroy
      # Update Redis cache to remove unfollowed user's time records
      Rails.logger.debug "! updating up new cache feed for user #{follow.follower_id} to unfollow user:#{follow.following_id}"

      UnfollowCacheJob.perform_async(follow.follower_id, follow.following_id)
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
