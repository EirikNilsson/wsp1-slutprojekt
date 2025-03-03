require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'securerandom'

class App < Sinatra::Base
  def db_connection
    db = SQLite3::Database.new 'db/users.sqlite'
    db.results_as_hash = true
    db
  end

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  get '/' do
    if session[:user_id]
      redirect '/training'
    else
      erb :index
    end
  end

  get '/signup' do
    erb :newuser 
  end

  post '/signup' do
    username = params[:username]
    plain_password = params[:password]
    password_hashed = BCrypt::Password.create(plain_password)
    db = db_connection
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password_hashed])
    redirect '/' 
  end

  post '/login' do
    request_username = params[:username]
    request_plain_password = params[:password]
    db = db_connection
    user = db.execute("SELECT * FROM users WHERE username = ?", request_username).first
    unless user
      status 401
      redirect '/unauthorized'
    end
    db_id = user["id"].to_i
    db_password_hashed = user["password"].to_s
    bcrypt_db_password = BCrypt::Password.new(db_password_hashed)
    if bcrypt_db_password == request_plain_password
      session[:user_id] = db_id
      redirect '/training'
    else
      status 401
      redirect '/unauthorized'
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/edit' do 
    erb :edit
  end
  
  post '/edit' do
    goal = params[:goal]
    days = params[:days].to_i
    duration = params[:duration].to_i
    db = db_connection
  
    existing_goal = db.execute("SELECT * FROM training_goals WHERE user_id = ?", session[:user_id]).first
  
    if existing_goal
      db.execute("UPDATE training_goals SET goal = ?, days = ?, duration = ? WHERE user_id = ?", [goal, days, duration, session[:user_id]])
    else
      db.execute("INSERT INTO training_goals (user_id, goal, days, duration) VALUES (?, ?, ?, ?)", [session[:user_id], goal, days, duration])
    end
  
    redirect '/training'
  end

  get '/unauthorized' do
    erb :unauthorized
  end

  get '/training' do
    db = db_connection
  
    # Hämta användarens träningsdata från databasen
    user_data = db.execute('SELECT goal, days, duration FROM training_goals WHERE user_id = ?', session[:user_id]).first
  
    if user_data
      @goal = user_data['goal']
      @days_per_week = user_data['days'].to_i
      @duration = user_data['duration']
  
      all_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  
      training_schedules = {
        1 => ["Wednesday"],
        2 => ["Monday", "Thursday"],
        3 => ["Monday", "Wednesday", "Friday"],
        4 => ["Monday", "Tuesday", "Thursday", "Saturday"],
        5 => ["Monday", "Tuesday", "Wednesday", "Friday", "Saturday"],
        6 => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        7 => all_days
      }
  
      selected_days = training_schedules[@days_per_week] || all_days.first(@days_per_week)
  
      # Skapa en struktur för alla dagar
      @days = all_days.map { |day| { day: day, exercises: [] } }
  
      # Hämta övningarna
      exercises = db.execute('SELECT exercise FROM exercises WHERE goal = ?', @goal)
  
      # Fördela övningarna
      if exercises.any?
        selected_days.each_with_index do |day, index|
          day_entry = @days.find { |d| d[:day] == day }
          day_entry[:exercises] << exercises[index % exercises.length]['exercise'] if day_entry
        end
      end
    else
      @goal = nil
      @days_per_week = nil
      @duration = nil
      @days = []
    end
  
    erb :training
  end
  
  get '/diet' do
    db = db_connection
  
    # Hämta användarens träningsmål från training_goals
    user_goal_data = db.execute('SELECT goal FROM training_goals WHERE user_id = ?', session[:user_id]).first
  
    if user_goal_data
      goal = user_goal_data['goal']
  
      # Hämta alla måltider för det valda målet
      meals = db.execute('SELECT meal, day FROM diets WHERE goal = ?', goal)
  
      # Skapa en struktur för alla dagar
      all_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      @days = all_days.map { |day| { day: day, meal: nil } }
  
      # Fyll i måltiderna för varje dag
      meals.each do |meal|
        day_entry = @days.find { |d| d[:day] == meal['day'] }
        day_entry[:meal] = meal['meal'] if day_entry
      end
    else
      @days = []
    end
  
    erb :diet
  end

  post '/log_weight' do
    weight = params[:weight].to_f
    date = params[:date]
    db = db_connection
  
    db.execute('INSERT INTO weights (user_id, weight, date) VALUES (?, ?, ?)', [session[:user_id], weight, date])
  
    redirect '/diet'
  end

  get '/weight_data' do
    db = db_connection
  
    # Hämta användarens viktdata
    weight_data = db.execute('SELECT date, weight FROM weights WHERE user_id = ? ORDER BY date', session[:user_id])
  
    # Formatera data för Chart.js
    dates = weight_data.map { |entry| entry['date'] }
    weights = weight_data.map { |entry| entry['weight'] }
  
    content_type :json
    { dates: dates, weights: weights }.to_json
  end
  
end
