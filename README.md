#Active Record (Lite)

This is my version of the useful tool for relating objects to a database.

### Active Record (Lite) gives us several mechanisms,
### the most important being the ability to:

* Represent models and their data.
* Represent associations between these models.
* Perform database operations in an object-oriented fashion.
* Avoid having to make SQL statements directly.

One particularly difficult association was **has_one_through** which required
clear naming in order to keep associations organized:

```ruby
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
```
[Associations](https://github.com/CroquetPro/ActiveRecordLite/blob/master/lib/associatable.rb)
