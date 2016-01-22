require_relative 'searchable'
require 'active_support/inflector'


class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    self.class_name.underscore.downcase + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]
    @foreign_key ||= "#{name}_id".to_sym # if @foreign_key.nil?
    @primary_key = options[:primary_key]
    @primary_key ||= :id #if @primary_key.nil?
    @class_name = options[:class_name]
    @class_name ||= name.to_s.singularize.camelcase #if @class_name.nil?
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    @foreign_key = options[:foreign_key]
    @foreign_key ||= "#{self_class_name.to_s.underscore.downcase}_id".to_sym # if @foreign_key.nil?
    @primary_key = options[:primary_key]
    @primary_key ||= :id #if @primary_key.nil?
    @class_name = options[:class_name]
    @class_name ||= name.to_s.singularize.camelcase #if @class_name.nil?
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method name do
      fk = options.send(:foreign_key)
      options.model_class.where({ id: self.send(fk) }).first
    end
  end

  def has_many(name, options = {})

    options = HasManyOptions.new(name, self, options)

    define_method name do
      fk = options.send(:foreign_key)
      pk = options.send(:primary_key)
      options.model_class.where({ fk => self.send(pk) })
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)

    define_method name do
      self_table = self.class.to_s.downcase + "s"

      through_options = self.class.assoc_options[through_name]
      through_primary_key = through_options.send(:primary_key)
      through_table = through_name.to_s.downcase + "s"

      key = self.send(through_options.send(:foreign_key))

      source_options = through_options.model_class.assoc_options[source_name]
      source_foreign_key = source_options.send(:foreign_key)
      source_primary_key = source_options.send(:primary_key)
      source_table = source_name.to_s.downcase + "s"

      results = DBConnection.execute(<<-SQL)
          SELECT #{source_table}.*
          FROM #{through_table}
          JOIN #{source_table}
            ON #{source_foreign_key} = #{source_table}.#{source_primary_key}
          WHERE #{through_table}.#{through_primary_key} = #{key}
        SQL
      source_options.model_class.new(results.first)
    end
  end
end

class SQLObject
  extend Associatable
end
