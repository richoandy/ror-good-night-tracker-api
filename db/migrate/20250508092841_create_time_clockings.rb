class CreateTimeClockings < ActiveRecord::Migration[8.0]
  def change
    create_table :time_clockings do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :clock_in
      t.datetime :clock_out

      t.timestamps
    end

    # Add index on user_id for time_clockings to optimize user-specific queries
    add_index :time_clockings, :user_id
  end
end
