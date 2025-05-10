class ClockingOutCacheJob
  include Sidekiq::Job
  include FormattedDurationHelper

  def perform(time_clocking_id)
    this_week = Time.current.strftime("%Y-%W")

    time_clocking = TimeClocking.find(time_clocking_id)
    user = time_clocking.user

    # Get all followers of the user that just performs clock-out action
    follower_ids = user.followers.pluck(:id)

    follower_ids.each do |follower_id|
      cache_key = "user:#{follower_id}:week:#{this_week}:following_list"

      # Get existing data from cache
      cached_data = JSON.parse(REDIS.get(cache_key) || "[]")

      # Format the new data
      duration_in_seconds = (time_clocking.clock_out - time_clocking.clock_in).to_f

      new_data = {
        id: time_clocking.id,
        user_id: time_clocking.user_id,
        clock_in: time_clocking.clock_in,
        clock_out: time_clocking.clock_out,
        duration: duration_in_seconds,
        duration_label: format_duration(duration_in_seconds)
      }

      # Add new data to array
      cached_data << new_data

      # Sort by duration (longest to shortest)
      sorted_data = cached_data.sort_by { |record| record["duration"].to_f }.reverse

      # Store back to Redis
      cache_expiration = Time.current.end_of_week.to_i - Time.current.to_i
      REDIS.setex(cache_key, cache_expiration, sorted_data.to_json)
    end
  end
end
