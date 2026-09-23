# SYNTAX TEST "source.ruby.rails" "migration methods"

class AddCommentsToPosts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
# ^^^^^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.migration.rails

  def change
    create_table :comments do |t|
#   ^^^^^^^^^^^^ support.function.activerecord.migration.rails
      t.references :post, null: false, foreign_key: true
#       ^^^^^^^^^^ support.function.activerecord.migration.rails
      t.string :author
#       ^^^^^^ support.function.activerecord.migration.rails
      t.text :body
#       ^^^^ support.function.activerecord.migration.rails
      t.jsonb :metadata
#       ^^^^^ support.function.activerecord.migration.rails
      t.uuid :token
#       ^^^^ support.function.activerecord.migration.rails
      t.timestamps
#       ^^^^^^^^^^ support.function.activerecord.migration.rails
      t.index [:post_id, :created_at]
#       ^^^^^ support.function.activerecord.migration.rails
    end

    change_table :posts do |t|
#   ^^^^^^^^^^^^ support.function.activerecord.migration.rails
      t.rename :title, :headline
#       ^^^^^^ support.function.activerecord.migration.rails
      t.remove :legacy, type: :string
#       ^^^^^^ support.function.activerecord.migration.rails
      t.change_default :status, from: nil, to: "draft"
#       ^^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    end

    add_column :posts, :published_at, :datetime
#   ^^^^^^^^^^ support.function.activerecord.migration.rails
    add_reference :posts, :author, foreign_key: { to_table: :users }
#   ^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    add_index :posts, :published_at, algorithm: :concurrently
#   ^^^^^^^^^ support.function.activerecord.migration.rails
    change_column_null :posts, :title, false
#   ^^^^^^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    rename_column :posts, :body, :content
#   ^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    add_check_constraint :posts, "rating >= 0", name: "rating_positive"
#   ^^^^^^^^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    create_enum :status, %w[draft published]
#   ^^^^^^^^^^^ support.function.activerecord.migration.rails
    enable_extension "pgcrypto"
#   ^^^^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    remove_column :posts, :legacy, :string
#   ^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    drop_table :tags
#   ^^^^^^^^^^ support.function.activerecord.migration.rails

    reversible do |direction|
#   ^^^^^^^^^^ support.function.activerecord.migration.rails
      direction.up { execute "UPDATE posts SET status = 'draft'" }
#                    ^^^^^^^ support.function.activerecord.migration.rails
    end
    up_only { execute "SELECT 1" }
#   ^^^^^^^ support.function.activerecord.migration.rails
    say_with_time "Backfilling" do
#   ^^^^^^^^^^^^^ support.function.activerecord.migration.rails
    end
  end
end

# Outside migrations these are regular names.
class Importer
  def run
    execute
#   ^^^^^^^ - support.function.activerecord.migration.rails
    say "hello"
#   ^^^ - support.function.activerecord.migration.rails
    row.string
#       ^^^^^^ - support.function.activerecord.migration.rails
  end
end
