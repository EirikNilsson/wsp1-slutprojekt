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
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT UNIQUE NOT NULL,
                  password TEXT NOT NULL)')

    db.execute('CREATE TABLE weeks (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  day TEXT NOT NULL)')

    db.execute('CREATE TABLE exercises (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  day TEXT NOT NULL,
                  exercise TEXT NOT NULL,
                  checkmark INTEGER DEFAULT 0,
                  FOREIGN KEY (week_id) REFERENCES weeks(week_id))')

    db.execute('CREATE TABLE weights (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  weight TEXT NOT NULL,
                  FOREIGN KEY (week_id) REFERENCES weeks(week_id))')

    db.execute('CREATE TABLE diets (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  dish TEXT NOT NULL,
                  checkmark INTEGER DEFAULT 0,
                  FOREIGN KEY (week_id) REFERENCES weeks(week_id))')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("189")
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', 
               ["eirik", password_hashed])

    days = [
      { week_id: 1, day: "Monday" },
      { week_id: 1, day: "Tuesday" },
      { week_id: 1, day: "Wednesday" },
      { week_id: 1, day: "Thursday" },
      { week_id: 1, day: "Friday" },
      { week_id: 1, day: "Saturday" },
      { week_id: 1, day: "Sunday" }
    ]

    days.each do |day|
      db.execute('INSERT INTO weeks (week_id, day) VALUES (?, ?)', [day[:week_id], day[:day]])
    end
    db.execute('INSERT INTO exercises (week_id, day, exercise, checkmark) VALUES (?, ?, ?, ?)', 
               [1, "Monday", "Push-ups", 1],)
    db.execute('INSERT INTO exercises (week_id, day, exercise, checkmark) VALUES (?, ?, ?, ?)', 
               [2, "Tuesday", "Burpies", 1],)
    db.execute('INSERT INTO weights (week_id, weight) VALUES (?, ?)', 
               [1, "70kg"])
    db.execute('INSERT INTO diets (week_id, dish, checkmark) VALUES (?, ?, ?)', 
               [1, "Chicken Salad", 1])
  end

  private

  def self.db
    @db ||= SQLite3::Database.new('db/users.sqlite').tap do |db|
      db.results_as_hash = true
    end
  end
end

Seeder.seed!
