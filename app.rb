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

  get '/training' do
    db = db_connection
  
    @days = [
      { day: "Monday", exercises: [] },
      { day: "Tuesday", exercises: [] },
      { day: "Wednesday", exercises: [] },
      { day: "Thursday", exercises: [] },
      { day: "Friday", exercises: [] },
      { day: "Saturday", exercises: [] },
      { day: "Sunday", exercises: [] }
    ]

    exercises = db.execute('SELECT day, exercise FROM exercises WHERE week_id = 1')
  
    exercises.each do |exercise|
      day_entry = @days.find { |d| d[:day] == exercise['day'] }
      day_entry[:exercises] << exercise['exercise'] if day_entry
    end
  
    erb :training
  end

  get '/diet' do
    erb :diet
  end

  get '/edit' do 
    erb :edit
  end

  post '/edit' do
    goal = params[:goal]
    days = params[:days].to_i
    duration = params[:duration].to_i
    db = db_connection
    db.execute("INSERT INTO training_goals (user_id, goal, days, duration) VALUES (?, ?, ?, ?)", [session[:user_id], goal, days, duration])
    redirect '/training'
  end

  get '/unauthorized' do
    erb :unauthorized
  end
end
