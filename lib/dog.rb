require 'pry'

class Dog
  attr_accessor :name, :breed, :id

  def initialize(attributes)
    @id = nil
    attributes.each do |key, value|
      self.class.attr_accessor(key)
      self.send(("#{key}="), value)
    end
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs
    SQL
    DB[:conn].execute(sql)
  end

  def save
    sql = <<-SQL
      INSERT INTO dogs (name, breed)
      VALUES (?, ?)
    SQL
    DB[:conn].execute(sql, self.name, self.breed)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    self # since the test just asked for method to return instance of Dog, I just had it return the instance via "self"
  end

  def self.create(hash)
    dog = Dog.new(hash)
    dog.save
  end

  def self.new_from_db(row)
    db_row = {id: row[0], name: row[1], breed: row[2]}
    dog = self.new(db_row)
    dog
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
    SQL
    db_row = DB[:conn].execute(sql, id).flatten
    Dog.new_from_db(db_row)
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
      ORDER BY name
      LIMIT 1
    SQL
    row = DB[:conn].execute(sql, name).flatten
    self.new_from_db(row)
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  def self.find_or_create_by(hash)
    dog = Dog.find_by_name(hash)
    if dog.id
        dog.update
    else 
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, name: "#{name}", breed: "#{breed}")
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end

  end

end
