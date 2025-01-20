
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
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT UNIQUE NOT NULL,
                  password TEXT NOT NULL
                )')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("189")
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', 
               ["eirik", password_hashed])
  end

  private

  def self.db
    @db ||= SQLite3::Database.new('db/users.sqlite').tap do |db|
      db.results_as_hash = true
    end
  end
end

Seeder.seed!
