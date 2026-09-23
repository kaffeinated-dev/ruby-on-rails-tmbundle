# SYNTAX TEST "source.ruby.rails" "schema.rb"

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000000) do
# <------------ meta.rails.schema
  create_table "users", force: :cascade do |t|
    t.string "name"
#   ^ meta.rails.schema meta.rails.migration.create_table
  end
end

ActiveRecord::Schema.define(version: 2019_01_01_000000) do
# <------------ meta.rails.schema
  create_table "posts", force: :cascade do |t|
    t.string "title"
#   ^ meta.rails.schema meta.rails.migration.create_table
  end
end
