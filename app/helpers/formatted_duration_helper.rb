module FormattedDurationHelper
  def format_duration(duration_in_seconds)
    if duration_in_seconds < 3600
      minutes = (duration_in_seconds / 60.0).round(2)
      "#{minutes} minutes"
    else
      hours = (duration_in_seconds / 3600.0).round(2)
      "#{hours} hours"
    end
  end
end
