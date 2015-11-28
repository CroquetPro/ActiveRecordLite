require_relative '03_associatable'
require 'byebug'
# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method name do
      self_table = self.class.to_s.downcase + "s"
      key = self.send(through_options.send(:foreign_key))

      through_options = self.class.assoc_options[through_name]
      through_primary_key = through_options.send(:primary_key)
      through_table = through_name.to_s.downcase + "s"

      source_options = through_options.model_class.assoc_options[source_name]
      source_foreign_key = source_options.send(:foreign_key)
      source_primary_key = source_options.send(:primary_key)
      source_table = source_name.to_s.downcase + "s"

      results = DBConnection.execute(<<-SQL)
          SELECT #{source_table}.*
          FROM #{through_table}
          JOIN #{source_table}
            ON #{source_foreign_key} = #{s_table}.#{source_primary_key}
          WHERE #{through_table}.#{through_primary_key} = #{key}
        SQL
      source_options.model_class.new(results.first)
    end
  end
end
