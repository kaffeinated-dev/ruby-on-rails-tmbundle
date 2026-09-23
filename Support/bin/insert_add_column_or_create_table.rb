#!/usr/bin/env ruby
# Second half of the ‘Drop / Create Table’ (mtab) and ‘Remove / Add Column’
# (mcol) snippets: completes drop_table or remove_column on the current line
# using the table’s definition in db/schema.rb.
#
# In a change method the line is made reversible (drop_table with a block of
# the table’s columns, remove_column with the column’s type and options). In
# migrations with a down method, create_table or add_column is inserted after
# ‘def down’ instead.
#
# usage: insert_add_column_or_create_table.rb < text from the current line to the end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails_navigator"

PLACEHOLDER = / ?\[press tab twice to generate (?:create_table|add_column)\]/

def give_up(message)
  print message
  exit 206
end

def complete(text, tables)
  current, *rest = text.lines
  current = current.to_s.sub(PLACEHOLDER, "")
  indentation = current[/\A[ \t]*/]
  down = rest.index { |line| line =~ /^\s*def\s+(?:self\.)?down\b/ }

  case current
  when /remove_column\s+:(\w+),\s*:(\w+)/ then table, column = $1, $2
  when /drop_table\s+:(\w+)/             then table = $1
  else give_up("There is no drop_table or remove_column on this line.")
  end
  columns = tables[table] or give_up("db/schema.rb has no table ‘#{table}’.")

  if column
    definition = columns.find { |c| c.name == column } or give_up("db/schema.rb has no column ‘#{column}’ in ‘#{table}’.")
    arguments = ":#{table}, :#{column}, :#{definition.type}#{", #{definition.options}" unless definition.options.empty?}"
    if down
      rest.insert(down + 1, "#{indentation}add_column #{arguments}\n")
    else
      current = current.sub(/remove_column\s+:#{table},\s*:#{column}\b.*?(\r?\n)?\z/) { "remove_column #{arguments}#{$1}" }
    end
  else
    key = columns.find { |c| c.options == "primary key" }
    table_options = if key.nil? then ", id: false" elsif key.type != "bigint" then ", id: :#{key.type}" else "" end
    body = columns.reject { |c| c.equal?(key) }.map do |c|
      "  t.#{c.type} \"#{c.name}\"#{", #{c.options}" unless c.options.empty?}\n"
    end
    if down
      block = "create_table :#{table}#{table_options} do |t|\n#{body.join}end\n"
      rest.insert(down + 1, block.lines.map { |line| indentation + line }.join)
    else
      current = current.sub(/drop_table\s+:#{table}\b.*?(\r?\n)?\z/) do
        "drop_table :#{table}#{table_options} do |t|\n" + body.map { |line| indentation + line }.join + "#{indentation}end#{$1}"
      end
    end
  end
  current + rest.join
end

if __FILE__ == $0
  text = $stdin.read
  root = RailsNavigator.root_for(ENV["TM_FILEPATH"] || ENV["TM_DIRECTORY"] || Dir.pwd) || ENV["TM_PROJECT_DIRECTORY"]
  tables = root && RailsNavigator.schema(root) or give_up("There is no db/schema.rb to take the definition from.")
  print complete(text, tables)
end
