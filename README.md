# Good Night - Time Clocking/Tracking API

A Ruby on Rails API for tracking work hours and following other users' time records within beginning of this week until end of this week.

## SQL Database Structure
    User {
        integer id
        string name
        datetime created_at
        datetime updated_at
    }

    TimeClocking {
        integer id
        integer user_id
        datetime clock_in
        datetime clock_out
        datetime created_at
        datetime updated_at
    }

    Follow {
        integer id
        integer follower_id (FK: User.id)
        integer following_id (FK: User.id)
        datetime created_at
        datetime updated_at
    }

## Available APIs

### Users

- `POST /users` - Create a new user
  - Body: `name` (string)

### Follows

- `POST /follows` - Follow a user
  - Body: `follower_id` (integer), `following_id` (integer)
- `DELETE /follows/:follower_id` - Unfollow a user
  - Query: `following_id` (integer)

### Time Clockings

- `POST /time_clockings/clock_in` - Clock in
  - Body: `user_id` (integer)
- `PATCH /time_clockings/clock_out` - Clock out
  - Body: `user_id` (integer)
- `GET /users/:user_id/time_records_of_following_list` - Get time records of users being followed by `:user_id`

### User Relationships

- `GET /users/:id/followers` - Get user's followers
- `GET /users/:id/following` - Get users's following list

### Health Check

- `GET /up` - Health check endpoint

## Getting Started

### Prerequisites

- Docker is installed
- Docker Compose is installed

### Running the Application

1. start docker containers
```
docker-compose up
```

This will start:
- PostgreSQL
- Redis

2. Migrate the database:
```
rails db:migrate
```

3. Seed the database:
```
rails db:seed
```

4. install dependencies:
```
bundle install
```

5. Start Sidekiq worker:
```
bundle exec sidekiq
```

6. Start the Main web-service at localhost:3000:
```
rails s
```

## Architecture
The application uses:
- Ruby on Rails for the API
- PostgreSQL for the database
- Sidekiq for background job processing
- Redis for Sidekiq job queue

## Time Clocking Explained
When a user clocks in: creates a new TimeClocking record with:
   - user_id
   - clock_in time (current time)
   - clock_out is nil (not set yet)

## When a user clocks out:
1. Finds the user's active clock-in record (where clock_out is nil)
2. Updates it with the current time as clock_out
3. Triggers ClockingOutCacheJob to update followers' caches

## Caching Strategy

### When user VIEW time-clocking feed:
1. Checks if data exists in cache for current week
2. If cached:
   - Returns cached data immediately
3. If not cached:
   - Fetches all time records for followed users
   - Formats the data
   - Caches it with TTL to end-of-week
   - Returns the data

### When user CLOCK OUT, `clocking_out_cache_job` will perform:
1. Gets all followers of the user who clocked out
2. For each follower:
   - Gets their existing cache
   - Adds the new clock-out record
   - Sorts records by duration (longest to shortest)
   - Saves back to Redis with TTL to end-of-week

### when user A FOLLOW user B, `following_cache_job` will perform:
1. Gets the user A's existing cached feed
2. Fetches all time records for the followed user for current week:
    - Only completed records (with clock_out)
    - Only records from current week
    - Sorted by duration (longest to shortest)
3. Combines with existing cached records and Sorts all records by duration
4. Saves back to Redis as JSON array with TTL to end-of-week

### when user A UNFOLLOW another user B. `unfollow_cache_job` will perform:
1. Gets the follower's existing cache
2. If cache exists:
    - Removes all records belonging to the unfollowed user
    - Maintains the order of remaining records
    - Saves filtered records back to Redis

### unit tests:
```
ruby test/unit/formatted_duration_helper_test.rb
```