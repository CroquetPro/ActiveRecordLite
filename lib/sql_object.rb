require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'

class SQLObject
  def self.table_name=(table_name)
  end

  def self.table_name
    self.to_s.downcase + "s"
  end

  def self.columns
    db = DBConnection.execute2("SELECT * FROM " + self.table_name)

    col_name_strings = db.first

    col_names = []
    col_name_strings.each { |str| col_names << str.to_sym }
    col_names
  end

  def self.finalize!
    columns.each do |column|
      define_method :attributes do
        @attributes ||= {}
      end

      define_method "#{column}" do
        attributes[column]
      end

      define_method "#{column}=" do |val|
        attributes[column] = val
      end
    end
  end


  def self.all
    parse_all(DBConnection.execute("SELECT * FROM " + self.table_name))
  end

  def self.parse_all(results)
    all_objects = []
    results.each { |attr_hash| all_objects << self.new(attr_hash) }
    all_objects
  end

  def self.find(id)
    table = self.table_name
    db_info = DBConnection.execute(<<-SQL, id)
        SELECT *
        FROM #{table}
        WHERE id = ?
        LIMIT 1
    SQL
    return nil if db_info.empty?
    self.new(db_info.first)
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      attr_sym = attr_name.to_sym
      unless self.class.columns.include?(attr_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      send "#{attr_name}=", val
    end
  end

  def attributes
  end

  def attribute_values
    self.class.columns.map do |attr_sym|
      send attr_sym
    end
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(", ")
    marks = (["?"] * cols.count).join(", ")
    table = self.class.table_name

    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO #{table} (#{col_names})
      VALUES (#{marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    table = self.class.table_name
    cols = self.class.columns.map { |attr_sym| "#{attr_sym} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE #{table}
      SET #{cols}
      WHERE id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
