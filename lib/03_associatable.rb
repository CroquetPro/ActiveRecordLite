require_relative '02_searchable'
require 'active_support/inflector'


# Phase IIIa
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
    @foreign_key = "#{name}_id".to_sym if @foreign_key.nil?
    @primary_key = options[:primary_key]
    @primary_key = :id if @primary_key.nil?
    @class_name = options[:class_name]
    @class_name = name.to_s.singularize.camelcase if @class_name.nil?
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    @foreign_key = options[:foreign_key]
    @foreign_key ||= "#{self_class_name.to_s.underscore.downcase}_id".to_sym# if @foreign_key.nil?
    @primary_key = options[:primary_key]
    @primary_key ||= :id #if @primary_key.nil?
    @class_name = options[:class_name]
    @class_name ||= name.to_s.singularize.camelcase #if @class_name.nil?
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method name do
      # debugger
      fk = options.send(:foreign_key)
      options.model_class.where({ id: self.send(fk) }).first
    end

    # ...
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
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end
