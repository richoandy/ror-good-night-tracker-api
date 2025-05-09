class FollowingCacheJob
  include Sidekiq::Job
  include FormattedDurationHelper

  def perform(follower_id, following_id)
    this_week = Time.current.strftime("%Y-%W")
    cache_key = "user:#{follower_id}:week:#{this_week}:following_list"

    # Get existing records from cache
    existing_records = REDIS.get(cache_key)
    records_array = existing_records ? JSON.parse(existing_records) : []

    # Get all time records for the following for this week
    start_of_week = Time.current.beginning_of_week
    end_of_week = Time.current.end_of_week

    time_records = TimeClocking
                    .where(user_id: following_id)
                    .where(clock_in: start_of_week..end_of_week)
                    .where.not(clock_out: nil)
                    .select("time_clockings.*, EXTRACT(EPOCH FROM (clock_out - clock_in)) AS duration")
                    .order("duration DESC")

    # Format the new records
    new_records = time_records.map do |record|
      {
        id: record.id,
        user_id: record.user_id,
        clock_in: record.clock_in,
        clock_out: record.clock_out,
        duration: FormattedDurationHelper.format_duration(record.duration)
      }
    end

    # Combine existing and new records
    all_records = records_array + new_records

    # Sort by duration (longest to shortest)
    sorted_data = all_records.sort_by { |record| record["duration"].to_f }.reverse

    # Store back to Redis as JSON array
    cache_expiration = end_of_week.to_i - Time.current.to_i
    REDIS.setex(cache_key, cache_expiration, sorted_data.to_json)
  end
end
