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
                  password TEXT NOT NULL,
                  role TEXT NOT NULL)')

    db.execute('CREATE TABLE goals (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  goal TEXT NOT NULL,
                  days_per_week INTEGER NOT NULL,
                  session_length INTEGER NOT NULL)')

    db.execute('CREATE TABLE weeks (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  day TEXT NOT NULL,
                  FOREIGN KEY (user_id) REFERENCES users(id))')

    db.execute('CREATE TABLE exercises (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  week_id INTEGER NOT NULL,
                  day TEXT NOT NULL,
                  exercise TEXT NOT NULL,
                  goal TEXT NOT NULL,
                  checkmark INTEGER DEFAULT 0,
                  FOREIGN KEY (week_id) REFERENCES weeks(id))')

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
    db.execute('CREATE TABLE IF NOT EXISTS user_exercises (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER,
                  day TEXT,
                  exercise TEXT,
                  goal TEXT,
                  FOREIGN KEY (user_id) REFERENCES users(id));')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("189")
    db.execute('INSERT INTO users (username, password, role) VALUES (?, ?, ?)', ["eirik", password_hashed, "admin"])

    goals = [
      { goal: "Build muscle", days: 5, session_length: 60 },
      { goal: "Lose weight", days: 4, session_length: 45 },
      { goal: "Improve endurance", days: 6, session_length: 50 }
    ]
    
    goals.each do |goal|
      db.execute('INSERT INTO goals (goal, days_per_week, session_length) VALUES (?, ?, ?)', 
                 [goal[:goal], goal[:days], goal[:session_length]])
    end

    # Skapa veckodagar för användaren
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    days.each do |day|
      db.execute('INSERT INTO weeks (user_id, day) VALUES (?, ?)', [1, day])
    end

    # Hämta week_id för dagarna
    week_ids = {}
    db.execute('SELECT id, day FROM weeks WHERE user_id = ?', [1]).each do |row|
      week_ids[row["day"]] = row["id"]
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
      { goal: "Lose weight", day: "Saturday", exercise: "Terrain running" },
      { goal: "Lose weight", day: "Sunday", exercise: "Running" },
    
      { goal: "Improve endurance", day: "Monday", exercise: "Long-distance Running" },
      { goal: "Improve endurance", day: "Tuesday", exercise: "Rowing Machine" },
      { goal: "Improve endurance", day: "Wednesday", exercise: "Interval Sprints" },
      { goal: "Improve endurance", day: "Thursday", exercise: "Jump Rope" },
      { goal: "Improve endurance", day: "Friday", exercise: "Burpees" },
      { goal: "Improve endurance", day: "Saturday", exercise: "Running" },
      { goal: "Improve endurance", day: "Sunday", exercise: "Terrain running" }
    ]
    
    exercises.each do |exercise|
      week_id = week_ids[exercise[:day]]
      db.execute('INSERT INTO exercises (week_id, day, exercise, goal, checkmark) VALUES (?, ?, ?, ?, ?)', 
                 [week_id, exercise[:day], exercise[:exercise], exercise[:goal], 0])
    end

    meals = [
      { meal: "Grilled Chicken with Quinoa", day: "Monday", goal: "Build muscle" },
      { meal: "Beef Steak with Broccoli", day: "Tuesday", goal: "Build muscle" },
      { meal: "Egg and Avocado Toast", day: "Wednesday", goal: "Build muscle" },
      { meal: "Protein Pancakes", day: "Thursday", goal: "Build muscle" },
      { meal: "Grilled Salmon with Asparagus", day: "Friday", goal: "Build muscle" },
      { meal: "Cottage Cheese with Berries and Nuts", day: "Saturday", goal: "Build muscle" },
      { meal: "Omelette with Spinach and Turkey", day: "Sunday", goal: "Build muscle" },
    
      { meal: "Grilled Fish with Steamed Vegetables", day: "Monday", goal: "Lose weight" },
      { meal: "Vegetable Soup", day: "Tuesday", goal: "Lose weight" },
      { meal: "Grilled Chicken Salad", day: "Wednesday", goal: "Lose weight" },
      { meal: "Zucchini Noodles with Pesto", day: "Thursday", goal: "Lose weight" },
      { meal: "Quinoa and Black Bean Salad", day: "Friday", goal: "Lose weight" },
      { meal: "Baked Cod with Roasted Veggies", day: "Saturday", goal: "Lose weight" },
      { meal: "Greek Yogurt with Berries and Seeds", day: "Sunday", goal: "Lose weight" },
    
      { meal: "Oatmeal with Banana and Almond Butter", day: "Monday", goal: "Improve endurance" },
      { meal: "Sweet Potato and Chickpea Curry", day: "Tuesday", goal: "Improve endurance" },
      { meal: "Grilled Chicken with Brown Rice", day: "Wednesday", goal: "Improve endurance" },
      { meal: "Lentil and Vegetable Stew", day: "Thursday", goal: "Improve endurance" },
      { meal: "Grilled Turkey Burger with Sweet Potato Fries", day: "Friday", goal: "Improve endurance" },
      { meal: "Whole Grain Pasta with Veggie Sauce", day: "Saturday", goal: "Improve endurance" },
      { meal: "Smoothie Bowl with Granola and Fruits", day: "Sunday", goal: "Improve endurance" }
    ];
    
    
    meals.each do |meal|
      db.execute('INSERT INTO diets (meal, day, goal) VALUES (?, ?, ?)', [meal[:meal], meal[:day], meal[:goal]])
    end
  end

  private

  def self.db
    @db ||= SQLite3::Database.new('db/TrainingProgramsitedeluxe:theveryfirst.sqlite').tap do |db| 
      db.results_as_hash = true
    end
  end
end

Seeder.seed!
