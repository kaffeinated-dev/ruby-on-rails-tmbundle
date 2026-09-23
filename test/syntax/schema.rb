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

ActiveRecord::Schema[8.1].define(version: 2025_01_01_000000) do
  enable_extension "pg_catalog.plpgsql"
# ^^^^^^^^^^^^^^^^ meta.rails.schema support.function.activerecord.migration.rails
  create_table "users", id: :uuid, force: :cascade do |t|
# ^^^^^^^^^^^^ meta.rails.schema support.function.activerecord.migration.rails
    t.string "email", null: false
#     ^^^^^^ meta.rails.schema meta.rails.migration.create_table support.function.activerecord.migration.rails
    t.index ["email"], name: "index_users_on_email", unique: true
#     ^^^^^ support.function.activerecord.migration.rails
  end
  add_foreign_key "posts", "users"
# ^^^^^^^^^^^^^^^ meta.rails.schema support.function.activerecord.migration.rails
end
