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
  
    db.execute('CREATE TABLE diets (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  meal TEXT NOT NULL,
                  day TEXT NOT NULL,
                  goal TEXT NOT NULL)')
  
    db.execute('CREATE TABLE weights (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  weight FLOAT NOT NULL,
                  date DATE NOT NULL,
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
      { goal: "Build muscle", day: "Saturday", exercise: "Bench Press" },
      { goal: "Build muscle", day: "Sunday", exercise: "Deadlifts" },
    
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
      db.execute('INSERT INTO exercises (week_id, day, exercise, goal, checkmark) VALUES (?, ?, ?, ?, ?)', 
                 [1, exercise[:day], exercise[:exercise], exercise[:goal], 0])
    end

    meals = [
      # Maträtter för "Build muscle"
      { meal: "Grilled Chicken with Quinoa", day: "Monday", goal: "Build muscle" },
      { meal: "Beef Steak with Broccoli", day: "Tuesday", goal: "Build muscle" },
      { meal: "Egg and Avocado Toast", day: "Wednesday", goal: "Build muscle" },
      { meal: "Protein Pancakes", day: "Thursday", goal: "Build muscle" },
      { meal: "Grilled Salmon with Asparagus", day: "Friday", goal: "Build muscle" },
      { meal: "Chicken and Rice Bowl", day: "Saturday", goal: "Build muscle" },
      { meal: "Turkey Meatballs with Pasta", day: "Sunday", goal: "Build muscle" },
    
      # Maträtter för "Lose weight"
      { meal: "Grilled Fish with Steamed Vegetables", day: "Monday", goal: "Lose weight" },
      { meal: "Vegetable Soup", day: "Tuesday", goal: "Lose weight" },
      { meal: "Grilled Chicken Salad", day: "Wednesday", goal: "Lose weight" },
      { meal: "Zucchini Noodles with Pesto", day: "Thursday", goal: "Lose weight" },
      { meal: "Quinoa and Black Bean Salad", day: "Friday", goal: "Lose weight" },
      { meal: "Grilled Shrimp with Cauliflower Rice", day: "Saturday", goal: "Lose weight" },
      { meal: "Vegetable Stir-Fry with Tofu", day: "Sunday", goal: "Lose weight" },
    
      # Maträtter för "Improve endurance"
      { meal: "Oatmeal with Banana and Almond Butter", day: "Monday", goal: "Improve endurance" },
      { meal: "Sweet Potato and Chickpea Curry", day: "Tuesday", goal: "Improve endurance" },
      { meal: "Grilled Chicken with Brown Rice", day: "Wednesday", goal: "Improve endurance" },
      { meal: "Lentil and Vegetable Stew", day: "Thursday", goal: "Improve endurance" },
      { meal: "Grilled Turkey Burger with Sweet Potato Fries", day: "Friday", goal: "Improve endurance" },
      { meal: "Vegetable and Quinoa Stuffed Peppers", day: "Saturday", goal: "Improve endurance" },
      { meal: "Pasta with Marinara Sauce and Grilled Chicken", day: "Sunday", goal: "Improve endurance" }
    ]
    
    meals.each do |meal|
      db.execute('INSERT INTO diets (meal, day, goal) VALUES (?, ?, ?)', [meal[:meal], meal[:day], meal[:goal]])
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