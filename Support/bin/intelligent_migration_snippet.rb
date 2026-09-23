#!/usr/bin/env ruby
#
# Copyright (c) 2006 Sami Samhuri
# Distributed under the MIT license
#
# Migration snippets for the ‘mcol’, ‘mind’, and ‘mtab’ macros. The current
# line is replaced by the snippet; in migrations with a down method, the
# reverse is inserted after ‘def down’. In a change method only the reversible
# forward code is inserted.
#
# usage: intelligent_migration_snippet.rb «snippet» < text from the current line to the end

SNIPPETS = {
  "rename_column" =>
    { up:   "rename_column :${1:table_name}, :${2:column_name}, :${3:new_column_name}$0",
      down: "rename_column :$1, :$3, :$2" },
  "rename_column_continue" =>
    { up:   "rename_column :${1:table_name}, :${2:column_name}, :${3:new_column_name}\nmncc$0",
      down: "rename_column :$1, :$3, :$2" },
  "rename_table" =>
    { up:   "rename_table :${1:old_table_name}, :${2:new_table_name}$0",
      down: "rename_table :$2, :$1" },
  "rename_table_continue" =>
    { up:   "rename_table :${1:old_table_name}, :${2:new_table_name}\nmntc$0",
      down: "rename_table :$2, :$1" },
  "change_column" =>
    { up:   "change_column :${1:table_name}, :${2:column_name}, :${3:string}$4",
      down: "change_column :$1, :$2, :${5:string}$6" },
  "change_column_default" =>
    { up:     'change_column_default :${1:table_name}, :${2:column_name}, ${3:"${4:new default}"}',
      down:   'change_column_default :$1, :$2, ${5:"${6:old default}"}',
      change: 'change_column_default :${1:table_name}, :${2:column_name}, from: ${3:nil}, to: ${4:"${5:new default}"}' },
  "add_remove_column" =>
    { up:   "add_column :${1:table_name}, :${2:column_name}, :${3:string}$0",
      down: "remove_column :$1, :$2" },
  "add_remove_column_continue" =>
    { up:   "add_column :${1:table_name}, :${2:column_name}, :${3:string}\nmarcc$0",
      down: "remove_column :$1, :$2" },
  "add_remove_timestamps" =>
    { up:   "add_timestamps :${1:table_name}$0",
      down: "remove_timestamps :$1" },
  "remove_add_timestamps" =>
    { up:   "remove_timestamps :${1:table_name}$0",
      down: "add_timestamps :$1" },
  "create_drop_table" =>
    { up:   "create_table :${1:table_name} do |t|\n  t.$0\n\n  t.timestamps\nend",
      down: "drop_table :$1" },
  "change_change_table" =>
    { up:   "change_table :${1:table_name} do |t|\n  t.$0\nend",
      down: "change_table :$1 do |t|\nend" },
  "add_remove_index" =>
    { up:   "add_index :${1:table_name}, :${2:column_name}$0",
      down: "remove_index :$1, :$2" },
  "add_remove_unique_index" =>
    { up:   "add_index :${1:table_name}, ${2:[:${3:column_name}${4:, :${5:column_name}}]}, unique: true$0",
      down: "remove_index :$1, column: $2" },
  "add_remove_named_index" =>
    { up:   'add_index :${1:table_name}, [:${2:column_name}${3:, :${4:column_name}}], name: "${5:index_name}"${6:, unique: true}$0',
      down: 'remove_index :$1, name: "$5"' },
}

def indent(code, indentation)
  code.lines.map { |line| line.strip.empty? ? line : indentation + line }.join
end

# Escape the characters that are special in snippets.
def escape_snippet(text)
  text.gsub(/[$`\\]/) { |c| "\\#{c}" }
end

def insert_migration(snippet, text)
  current, *rest = text.lines
  indentation = current.to_s[/\A[ \t]*/]
  down = rest.index { |line| line =~ /^\s*def\s+(?:self\.)?down\b/ }
  rest = rest.map { |line| escape_snippet(line) }
  if down
    rest.insert(down + 1, indent(snippet[:down], indentation) + "\n")
    code = snippet[:up]
  else
    code = snippet[:change] || snippet[:up]
  end
  indent(code, indentation) + "\n" + rest.join
end

if __FILE__ == $0
  text = $stdin.read
  snippet = SNIPPETS[ARGV[0]]
  print snippet ? insert_migration(snippet, text) : escape_snippet(text)
end
