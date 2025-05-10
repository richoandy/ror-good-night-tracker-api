require_relative "test_helper"

class FormattedDurationHelperTest < Minitest::Test
  include FormattedDurationHelper

  def test_formats_duration_less_than_1_hour_in_minutes
    assert_equal "30.0 minutes", format_duration(1800)  # 30 minutes
    assert_equal "45.5 minutes", format_duration(2730)  # 45.5 minutes
    assert_equal "59.98 minutes", format_duration(3599) # Just under 1 hour
  end

  def test_formats_duration_of_1_hour_or_more_in_hours
    assert_equal "1.0 hours", format_duration(3600)     # 1 hour
    assert_equal "1.5 hours", format_duration(5400)     # 1.5 hours
    assert_equal "2.5 hours", format_duration(9000)     # 2.5 hours
  end

  def test_handles_zero_duration
    assert_equal "0.0 minutes", format_duration(0)
  end

  def test_rounds_to_2_decimal_places
    assert_equal "1.23 minutes", format_duration(74)    # 1.23333... minutes
    assert_equal "1.23 hours", format_duration(4440)    # 1.23333... hours
  end
end
