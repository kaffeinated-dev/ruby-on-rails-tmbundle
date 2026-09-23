# SYNTAX TEST "source.ruby.rails" "migrations"

class CreateUsers < ActiveRecord::Migration[7.1]
# <----- meta.rails.migration keyword.control.class.ruby
  def change
    create_table :users do |t|
#   ^^^^^^^^^^^^ meta.rails.migration meta.rails.migration.create_table
      t.string :name
#     ^ meta.rails.migration meta.rails.migration.create_table
    end

    change_table :posts do |t|
      t.remove :body
#     ^ meta.rails.migration meta.rails.migration.change_table
    end
  end
end
