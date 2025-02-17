require 'sqlite3'
require 'bcrypt'

class Seeder
  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS exercises')
    db.execute('DROP TABLE IF EXISTS weights')
    db.execute('DROP TABLE IF EXISTS diets')
    db.execute('DROP TABLE IF EXISTS weeks')
    db.execute('DROP TABLE IF EXISTS goals')
    db.execute('DROP TABLE IF EXISTS training_goals')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT UNIQUE NOT NULL,
                  password TEXT NOT NULL)')

    db.execute('CREATE TABLE goals (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  goal TEXT NOT NULL,
                  days_per_week INTEGER NOT NULL,
                  session_length INTEGER NOT NULL)')

    db.execute('CREATE TABLE weeks (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  day TEXT NOT NULL)')

    db.execute('CREATE TABLE exercises (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  day TEXT NOT NULL,
                  exercise TEXT NOT NULL,
                  goal TEXT NOT NULL,
                  checkmark INTEGER DEFAULT 0,
                  FOREIGN KEY (week_id) REFERENCES weeks(week_id))')

    db.execute('CREATE TABLE training_goals (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  goal TEXT NOT NULL,
                  days INTEGER NOT NULL,
                  duration INTEGER NOT NULL,
                  FOREIGN KEY (user_id) REFERENCES users(id))')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("189")
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ["eirik", password_hashed])

    goals = [
      { goal: "Build muscle", days: 5, session_length: 60 },
      { goal: "Lose weight", days: 4, session_length: 45 },
      { goal: "Improve endurance", days: 6, session_length: 50 }
    ]
    
    goals.each do |goal|
      db.execute('INSERT INTO goals (goal, days_per_week, session_length) VALUES (?, ?, ?)', 
                 [goal[:goal], goal[:days], goal[:session_length]])
    end

    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    days.each do |day|
      db.execute('INSERT INTO weeks (week_id, day) VALUES (?, ?)', [1, day])
    end

    exercises = [
      { goal: "Build muscle", day: "Monday", exercise: "Bench Press" },
      { goal: "Build muscle", day: "Tuesday", exercise: "Squats" },
      { goal: "Build muscle", day: "Wednesday", exercise: "Deadlifts" },
      { goal: "Build muscle", day: "Thursday", exercise: "Pull-ups" },
      { goal: "Build muscle", day: "Friday", exercise: "Dumbbell Rows" },
    
      { goal: "Lose weight", day: "Monday", exercise: "Treadmill Running" },
      { goal: "Lose weight", day: "Tuesday", exercise: "Jump Rope" },
      { goal: "Lose weight", day: "Wednesday", exercise: "Cycling" },
      { goal: "Lose weight", day: "Thursday", exercise: "Swimming" },
      { goal: "Lose weight", day: "Friday", exercise: "HIIT Circuit" },
    
      { goal: "Improve endurance", day: "Monday", exercise: "Long-distance Running" },
      { goal: "Improve endurance", day: "Tuesday", exercise: "Rowing Machine" },
      { goal: "Improve endurance", day: "Wednesday", exercise: "Interval Sprints" },
      { goal: "Improve endurance", day: "Thursday", exercise: "Jump Rope" },
      { goal: "Improve endurance", day: "Friday", exercise: "Burpees" }
    ]
    
    exercises.each do |exercise|
      # Insert exercise with correct goal, day, and week_id
      db.execute('INSERT INTO exercises (week_id, day, exercise, goal, checkmark) VALUES (?, ?, ?, ?, ?)', 
                 [1, exercise[:day], exercise[:exercise], exercise[:goal], 0])
    end
  end

  private

  def self.db
    @db ||= SQLite3::Database.new('db/users.sqlite').tap do |db| 
      db.results_as_hash = true
    end
  end
end

Seeder.seed!
