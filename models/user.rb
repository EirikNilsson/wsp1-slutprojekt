class User

    def self.db
        return @db if @db
        @db = SQLite3::Database.new("db/users.sqlite")
        @db.results_as_hash = true
        return @db
     end

    def self.all 
        return db.execute('SELECT * FROM users')
    end

    def self.delete(id)
        db.execute("DELETE FROM users WHERE id = ?", [id])
    end


    def self.create(username:, password:)
        return db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password])
    end
    


end