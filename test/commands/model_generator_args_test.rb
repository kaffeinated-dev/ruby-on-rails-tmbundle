require "minitest/autorun"
require "open3"

class ModelGeneratorArgsTest < Minitest::Test
  SCRIPT = File.expand_path("../../Support/bin/model_generator_args.rb", __dir__)

  def run_script(source, line = nil)
    Open3.capture2e("ruby", SCRIPT, *[line].compact.map(&:to_s), stdin_data: source)
  end

  def args_for(source, line = nil)
    output, status = run_script(source, line)
    assert status.success?, output
    output.lines.map(&:chomp)
  end

  def test_generated_migration
    assert_equal %w[invoices number:string total:decimal{10,2} customer:references], args_for(<<~RUBY)
      class CreateInvoices < ActiveRecord::Migration[8.1]
        def change
          create_table :invoices do |t|
            t.string :number
            t.decimal :total, precision: 10, scale: 2
            t.references :customer, null: false, foreign_key: true

            t.timestamps
          end
        end
      end
    RUBY
  end

  COMPLEX = <<~RUBY
    class CreateCommentsAndTags < ActiveRecord::Migration[8.1]
      def change
        create_table :comments, id: :uuid do |t|
          t.references :commentable, polymorphic: true, null: false
          t.belongs_to :author, foreign_key: { to_table: :users }
          t.string :title, :subtitle, limit: 120
          t.text :body # the comment
          t.string :email, index: { unique: true }
          t.integer :position, index: true
          t.column :score, :float
          t.decimal :rating, precision: 3
          t.jsonb :metadata, default: {}
          t.timestamps
          t.index [:commentable_type, :commentable_id]
        end

        create_table "tags" do |t|
          t.string "name", null: false
        end
      end
    end
  RUBY

  def test_column_options_references_and_primary_key_type
    assert_equal %w[
      comments commentable:references{polymorphic} author:references title:string{120} subtitle:string{120} body:text
      email:string:uniq position:integer:index score:float rating:decimal{3} metadata:jsonb --primary-key-type=uuid
    ], args_for(COMPLEX, 5)
  end

  def test_uses_table_around_line
    assert_equal %w[tags name:string], args_for(COMPLEX, 18)
    assert_equal "comments", args_for(COMPLEX).first
  end

  def test_rejects_migration_without_create_table
    output, status = run_script("class AddEmail < ActiveRecord::Migration[8.1]\n  def change\n    add_column :users, :email, :string\n  end\nend\n")
    refute status.success?
    assert_match(/no create_table/, output)
  end
end
