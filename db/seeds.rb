# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Cleaning database..."
TimeClocking.destroy_all
Follow.destroy_all
User.destroy_all

# Create users
puts "Creating users..."
riko = User.create!(name: "RIKO")
andi = User.create!(name: "ANDI")
bong = User.create!(name: "BONG")

# Create follows
puts "Creating follows..."
Follow.create!(follower: riko, following: andi)
Follow.create!(follower: riko, following: bong)

# Create time clocking records
puts "Creating time clocking records..."

# Helper method to create time records
def create_time_records(user, start_date, days)
  days.times do |i|
    current_date = start_date + i.days
    clock_in = current_date.change(hour: 22, min: 0)  # 10:00 PM
    clock_out = (current_date + 1.day).change(hour: 6, min: 0)  # 6:00 AM next day

    TimeClocking.create!(
      user: user,
      clock_in: clock_in,
      clock_out: clock_out
    )
  end
end

# Create time records for the past week
start_date = Time.current.beginning_of_week - 1.week
create_time_records(andi, start_date, 7)
create_time_records(bong, start_date, 7)

puts "Seed data created successfully!"
