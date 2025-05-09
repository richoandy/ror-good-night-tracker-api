class UnfollowCacheJob
  include Sidekiq::Job

  def perform(follower_id, following_id)
    this_week = Time.current.strftime("%Y-%W")
    cache_key = "user:#{follower_id}:week:#{this_week}:following_list"

    # Get existing records from cache
    existing_records = REDIS.get(cache_key)
    return unless existing_records # Exit if no cache exists

    records_array = JSON.parse(existing_records)

    # Remove records from the unfollowed user while maintaining array order
    filtered_records = records_array.reject { |record| record["user_id"] == following_id }

    # Store back to Redis as JSON array
    cache_expiration = Time.current.end_of_week.to_i - Time.current.to_i
    REDIS.setex(cache_key, cache_expiration, filtered_records.to_json)
  end
end
