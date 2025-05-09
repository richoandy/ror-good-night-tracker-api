require "redis"
require_relative "../../config/initializers/redis"

class TimeClockingsController < ApplicationController
  include FormattedDurationHelper
  before_action :validate_user_exists, only: [ :clock_in, :clock_out ]

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

    following_ids = user.followings.pluck(:id)

    start_of_last_week = 1.week.ago.beginning_of_week
    end_of_last_week = 1.week.ago.end_of_week

    time_records = TimeClocking
                    # .where(clock_in: start_of_last_week..end_of_last_week)
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

    render json: formatted_records, status: :ok
  end
end

  private

  def validate_user_exists
    user_id = params[:user_id]

    if user_id.blank?
      render json: { error: "Missing user ID" }, status: :bad_request and return
    end

    unless User.exists?(user_id)
      render json: { error: "Invalid user ID" }, status: :unprocessable_entity and return
    end
  end
