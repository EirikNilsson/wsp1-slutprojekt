require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'securerandom'
require_relative 'models/user'

class App < Sinatra::Base
  def db_connection
    db = SQLite3::Database.new 'db/TrainingProgramsitedeluxe:theveryfirst.sqlite'
    db.results_as_hash = true
    db
  end

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  get '/' do 
    redirect '/login'
  end

  get '/login' do
    if session[:user_id]
      redirect '/training'
    else
      erb(:"users/index")
    end
  end

  get '/users' do
    @users = User.all();
    erb(:"users/show")
  end

  post '/users/deleteAll' do
      User.deleteAll
      redirect("/login")
  end
 

  get '/users/:id' do
    redirect '/login' unless session[:user_id]
  
    db = db_connection
    user = db.execute("SELECT * FROM users WHERE id = ?", [params[:id]]).first
    
    if user
      "Logged in as: #{user['username']}"
    else
      "User not found"
    end
  end

  post '/users/:id/delete' do
    redirect '/login' unless session[:user_id] == params[:id].to_i
    User.delete(params[:id])
    session.clear
  

    redirect '/login'
  end

  get '/signup' do
    erb(:"users/new")
  end

  post '/signup' do
    username = params[:username]
    plain_password = params[:password]
    password_hashed = BCrypt::Password.create(plain_password)
    @users = User.create(username: username, password: password_hashed)
    
    redirect '/login' 
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
    redirect '/login'
  end

  get '/new' do 
    erb(:"programs/new")
  end
  
  post '/create' do
      if !session[:user_id]
        redirect("/login")
      end
      goal = params[:goal]
      days = params[:days].to_i
      duration = params[:duration].to_i
      user_id = session[:user_id].to_i
      db = db_connection

      existing = db.execute("SELECT * FROM user_exercises WHERE user_id = ?", [user_id])

      if existing.empty? || existing.first["goal"] != goal
        db.execute("DELETE FROM user_exercises WHERE user_id = ?", [user_id])
      
        training_schedules = {
          1 => ["Wednesday"],
          2 => ["Monday", "Thursday"],
          3 => ["Monday", "Wednesday", "Friday"],
          4 => ["Monday", "Tuesday", "Thursday", "Saturday"],
          5 => ["Monday", "Tuesday", "Wednesday", "Friday", "Saturday"],
          6 => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
          7 => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
      
        selected_days = training_schedules[days]
        all_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      
        # Skapa en rad för varje veckodag, med NULL som övning
        all_days.each do |day|
          db.execute("INSERT INTO user_exercises (user_id, day, exercise, goal) VALUES (?, ?, NULL, ?)", [user_id, day, goal])
        end
      
        # Hämta default-övningar för målet
        default_exercises = db.execute("SELECT exercise FROM exercises WHERE goal = ?", [goal])
      
        # Uppdatera endast utvalda träningsdagar med övningar
        selected_days.each_with_index do |day, i|
          db.execute("UPDATE user_exercises SET exercise = ? WHERE user_id = ? AND day = ? AND goal = ?", 
                      [default_exercises[i % default_exercises.length]["exercise"], user_id, day, goal])
        end
      end
      
    
      existing_goal = db.execute("SELECT * FROM training_goals WHERE user_id = ?", session[:user_id]).first
    
      if existing_goal
        db.execute("UPDATE training_goals SET goal = ?, days = ?, duration = ? WHERE user_id = ?", [goal, days, duration, session[:user_id]])
      else
        db.execute("INSERT INTO training_goals (user_id, goal, days, duration) VALUES (?, ?, ?, ?)", [session[:user_id], goal, days, duration])
      end

      
    
    redirect '/training'
  end

  get '/unauthorized' do
    erb(:"users/unauthorized")
  end

  get '/training' do
    if !session[:user_id]
      redirect("/login")
    end
    db = db_connection
    @role = db.execute('SELECT role FROM users WHERE id = ?', session[:user_id]).first
    
    # Hämta alla användare om rollen är admin
    if @role["role"] == "admin"
      @users = db.execute("SELECT * FROM users")
    end
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
      exercises = db.execute('SELECT exercise FROM user_exercises WHERE goal = ?', @goal)
  
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
  
    erb(:"programs/index")
  end

  get '/edit' do
    if !session[:user_id]
      redirect("/login")
    end
    db = db_connection
    user_data = db.execute('SELECT goal, days, duration FROM training_goals WHERE user_id = ?', session[:user_id]).first
  
    if user_data
      @goal = user_data['goal']
      @days_per_week = user_data['days'].to_i
      @duration = user_data['duration']
  
      all_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      
      # Hämta ALLA övningar för användaren (oavsett goal)
      user_exercises = db.execute('SELECT day, exercise FROM user_exercises WHERE user_id = ?', session[:user_id])
  
      # Bygg dagstrukturen
      @days = all_days.map do |day|
        exercise_entry = user_exercises.find { |e| e['day'] == day }
        { 
          day: day,
          exercises: exercise_entry && !exercise_entry['exercise'].nil? ? [exercise_entry['exercise']] : []
        }
      end
    end
  
    erb(:"programs/edit")
  end
  
  

  post '/exercises/add' do
    db = db_connection
    old_exercise = params["old_exercise"]
    new_exercise = params["new_exercise"]
    day = params["day"]
  
    if session[:user_id].nil?
      halt 403, "You must be logged in to add exercises."
    end
  
    if old_exercise.nil? || old_exercise.strip.empty?
      # Fall: exercise är NULL – då uppdaterar vi raden där det är NULL
      db.execute(
        'UPDATE user_exercises SET exercise = ? WHERE user_id = ? AND day = ? AND exercise IS NULL',
        [new_exercise, session[:user_id], day]
      )
    else
      # Fall: vanlig update (ändrar befintlig övning)
      db.execute(
        'UPDATE user_exercises SET exercise = ? WHERE user_id = ? AND day = ? AND exercise = ?',
        [new_exercise, session[:user_id], day, old_exercise]
      )
    end
  
    redirect '/edit'
  end

  
  

  post '/exercises/delete' do
    db = db_connection
    
    old_exercise = params["old_exercise"]
    new_exercise = nil
    
    db.execute('UPDATE user_exercises SET exercise = ? WHERE user_id = ? AND day = ? AND exercise = ?', [new_exercise, session[:user_id], params[:day], params[:old_exercise]])

  
    redirect '/edit'  
  end
  

  
  post '/exercises/update' do
    db = db_connection
  
    old_exercise = params["old_exercise"]
    new_exercise = params["new_exercise"]
    day = params["day"]
  
    if old_exercise.strip.empty? || new_exercise.strip.empty?
      halt 400, "Ogiltig övning"
    end
  
    db.execute('UPDATE user_exercises SET exercise = ? WHERE user_id = ? AND day = ? AND exercise = ?', [params[:new_exercise], session[:user_id], params[:day], params[:old_exercise]])

  
    redirect '/edit'
  end
  

  post '/exercises/delete_all' do
    db = db_connection
    db.execute("DELETE FROM user_exercises")

    redirect '/training'
  end

  
  
  
  get '/diet' do
    db = db_connection
  
    user_goal_data = db.execute('SELECT goal FROM training_goals WHERE user_id = ?', session[:user_id]).first
  
    if user_goal_data
      goal = user_goal_data['goal']
  
      meals = db.execute('SELECT meal, day FROM diets WHERE goal = ?', goal)

      all_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      @days = all_days.map { |day| { day: day, meal: nil } }

      meals.each do |meal|
        day_entry = @days.find { |d| d[:day] == meal['day'] }
        day_entry[:meal] = meal['meal'] if day_entry
      end
    else
      @days = []
    end
  
    erb(:"programs/diet")
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
  
    weight_data = db.execute('SELECT date, weight FROM weights WHERE user_id = ? ORDER BY date', session[:user_id])

    dates = weight_data.map { |entry| entry['date'] }
    weights = weight_data.map { |entry| entry['weight'] }
  
    content_type :json
    { dates: dates, weights: weights }.to_json
  end
  
end
