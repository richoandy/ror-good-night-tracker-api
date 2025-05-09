require "redis"
require_relative "../../config/initializers/redis"

class TimeClockingsController < ApplicationController
  include FormattedDurationHelper
  before_action :validate_user_exists, only: [ :clock_in, :clock_out, :list_time_records_of_following_list ]

  def clock_in
    new_data = TimeClocking.new(user_id: params[:user_id], clock_in: Time.current)

    if new_data.save
      render json: { message: "Clocked in successfully", record: new_data }, status: :created
    else
      render json: { errors: new_data }, status: :unprocessable_entity
    end
  end

  def clock_out
    # First check if there are any records for this user
    user_records = TimeClocking.where(user_id: params[:user_id])

    if user_records.empty?
      render json: {
        error: "No clock records found for this user",
        user_id: params[:user_id]
      }, status: :not_found
      return
    end

    # Then check for active clock-in
    record = TimeClocking.where(user_id: params[:user_id], clock_out: nil).order(clock_in: :desc).first

    if record
      record.update(clock_out: Time.current)

      # Update cached feed for all followers in the background job
      ClockingOutCacheJob.perform_async(record.id)

      render json: {
        message: "Clocked out successfully",
        record: record
      }, status: :ok
    else
      # Check if all records are already clocked out
      if user_records.all? { |r| r.clock_out.present? }
        render json: {
          error: "All records are already clocked out",
          user_id: params[:user_id]
        }, status: :not_found
      else
        render json: {
          error: "No active clock-in record found",
          user_id: params[:user_id]
        }, status: :not_found
      end
    end
  end

  def list_time_records_of_following_list
    user = User.find(params[:user_id])
    this_week = Time.current.strftime("%Y-%W")

    # Check if data exists in cache
    cache_key = "user:#{user.id}:week:#{this_week}:following_list"
    cached_data = REDIS.get(cache_key)

    if cached_data.present?
      # Parse the cached JSON array
      Rails.logger.debug "-> Response with Cache Data: #{JSON.parse(cached_data)}"
      render json: JSON.parse(cached_data), status: :ok
    else
      following_ids = user.followings.pluck(:id)

      start_of_this_week = Time.current.beginning_of_week
      end_of_this_week = Time.current.end_of_week

      time_records = TimeClocking
                      .where(created_at: start_of_this_week..end_of_this_week)
                      .where(user_id: following_ids)
                      .where.not(clock_out: nil)
                      .select("time_clockings.*, EXTRACT(EPOCH FROM (clock_out - clock_in)) AS duration")
                      .order("duration DESC")

      formatted_records = time_records.map do |record|
        duration_in_seconds = record.duration
        record.attributes.merge(
          "duration" => format_duration(duration_in_seconds)
        )
      end

    if time_records.any?
      cache_expiration = Time.current.end_of_week.to_i - Time.current.to_i

      REDIS.setex(cache_key, cache_expiration, formatted_records.to_json)
      Rails.logger.debug "! new cache is set -> key: #{cache_key} #{formatted_records.to_json}"
    end
      render json: formatted_records.to_json, status: :ok
    end
  end

  private

  def validate_user_exists
    user_id = params[:user_id]

    if user_id.blank?
      render json: { error: "Missing user ID" }, status: :bad_request and return
    end

    unless User.exists?(user_id)
      render json: { error: "user ID not found" }, status: :unprocessable_entity and return
    end
  end
end
