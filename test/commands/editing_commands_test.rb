require "minitest/autorun"
require "tmpdir"
require "fileutils"

BIN = File.expand_path("../../Support/bin", __dir__)
ROOT_DIR = Dir.mktmpdir("rails-commands")
Minitest.after_run { FileUtils.rm_rf(ROOT_DIR) }

{
  "bin/rails" => "",
  "app/controllers/posts_controller.rb" => "class PostsController < ApplicationController\nend\n",
  "app/views/posts/index.html.erb" => "<h1>Posts</h1>\n<%= render \"form\" %>\n<%= render @posts %>\n",
  "app/views/posts/_form.html.erb" => "<form>\n</form>\n",
  "app/views/posts/_post.html.erb" => "<p><%= post.title %></p>\n",
  "test/fixtures/users.yml" => "david:\n  name: David\n\n# a comment\ndaniel-k:\n  name: Daniel\n\nsarah: # admin\n  name: Sarah\n",
  "db/schema.rb" => <<~RUBY,
    ActiveRecord::Schema[8.1].define(version: 1) do
      create_table "posts", id: :uuid, force: :cascade do |t|
        t.string "title", null: false, default: ""
        t.text "body"
      end
    end
  RUBY
}.each do |path, content|
  FileUtils.mkdir_p(File.join(ROOT_DIR, File.dirname(path)))
  File.write(File.join(ROOT_DIR, path), content)
end

ENV["RAILS_ROOT"] = ROOT_DIR
ENV["TM_FILEPATH"] = File.join(ROOT_DIR, "app/views/posts/index.html.erb")
$LOAD_PATH.unshift File.expand_path("../../Support/lib", __dir__)
$VERBOSE, verbose = nil, $VERBOSE # the scripts each define a UI constant
%w[intelligent_migration_snippet insert_add_column_or_create_table fixture_complete documentation help partial].each { |s| load File.join(BIN, "#{s}.rb") }
$VERBOSE = verbose

class MigrationMacrosTest < Minitest::Test
  CHANGE = "    \n  end\nend\n"
  UP_DOWN = "    \n  end\n\n  def down\n  end\nend\n"

  def test_change_migration_gets_forward_code_and_escaped_rest
    result = insert_migration(SNIPPETS["add_remove_column"], "    \n  end\n  # $5 `x`\nend\n")
    assert_equal "    add_column :${1:table_name}, :${2:column_name}, :${3:string}$0\n  end\n  # \\$5 \\`x\\`\nend\n", result
  end

  def test_change_migration_uses_reversible_column_default
    assert_match(/change_column_default .*from: \$\{3:nil\}, to:/, insert_migration(SNIPPETS["change_column_default"], CHANGE))
  end

  def test_up_down_migration_gets_reverse_after_def_down
    result = insert_migration(SNIPPETS["add_remove_index"], UP_DOWN)
    assert_equal "    add_index :${1:table_name}, :${2:column_name}$0\n  end\n\n  def down\n    remove_index :$1, :$2\n  end\nend\n", result
  end

  def test_multi_line_snippets_are_indented
    assert_equal "    create_table :${1:table_name} do |t|\n      t.$0\n\n      t.timestamps\n    end\n  end\nend\n", insert_migration(SNIPPETS["create_drop_table"], CHANGE)
  end

  def tables
    RailsNavigator.schema(ROOT_DIR)
  end

  def test_remove_column_becomes_reversible
    text = "    remove_column :posts, :title [press tab twice to generate add_column]\n  end\nend\n"
    assert_equal "    remove_column :posts, :title, :string, null: false, default: \"\"\n  end\nend\n", complete(text, tables)
  end

  def test_drop_table_becomes_reversible
    text = "    drop_table :posts [press tab twice to generate create_table]\n  end\nend\n"
    expected = "    drop_table :posts, id: :uuid do |t|\n      t.string \"title\", null: false, default: \"\"\n      t.text \"body\"\n    end\n  end\nend\n"
    assert_equal expected, complete(text, tables)
  end

  def test_up_down_migration_gets_create_table_after_def_down
    text = "    drop_table :posts [press tab twice to generate create_table]\n  end\n\n  def down\n  end\nend\n"
    assert_match(/  def down\n    create_table :posts, id: :uuid do \|t\|\n      t.string "title"/, complete(text, tables))
  end

  def test_unknown_table
    assert_output("db/schema.rb has no table ‘nope’.") do
      error = assert_raises(SystemExit) { complete("drop_table :nope\n", tables) }
      assert_equal 206, error.status
    end
  end
end

class FixtureCompleteTest < Minitest::Test
  def test_labels
    assert_equal %w[david daniel-k sarah], fixture_labels(ROOT_DIR, "user")
    assert_nil fixture_labels(ROOT_DIR, "comment")
  end

  def test_fixture_reference
    reference, typed, complete = parse("  user: da\n", true, false, 0)
    assert_equal ["user", "da"], [reference, typed]
    assert_equal "  user: david\n", complete["david"]
  end

  def test_fixture_list
    reference, typed, complete = parse("  users: sarah, da", true, true, 0)
    assert_equal ["users", "da"], [reference, typed]
    assert_equal "  users: sarah, david", complete["david"]
  end

  def test_test_reference_at_caret
    line = "    assert users(:da).admin?, posts(:one)\n"
    reference, typed, complete = parse(line, false, false, 18)
    assert_equal ["users", "da"], [reference, typed]
    assert_equal "    assert users(:david).admin?, posts(:one)\n", complete["david"]
    assert_equal "    assert users(:\"daniel-k\").admin?, posts(:one)\n", complete["daniel-k"]
  end
end

class DocumentationTest < Minitest::Test
  INDEX = [
    ["has_many", "ActiveRecord::Associations::ClassMethods", "classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many", "", ""],
    ["find", "ActiveRecord::FinderMethods", "classes/ActiveRecord/FinderMethods.html#method-i-find", "", ""],
    ["find", "ActiveRecord::Core::ClassMethods", "classes/ActiveRecord/Core/ClassMethods.html#method-i-find", "", ""],
    ["ActiveRecord::Base", "", "classes/ActiveRecord/Base.html", "", ""],
    ["ActionController::Base", "", "classes/ActionController/Base.html", "", ""],
    ["base", "ActiveStorage::Filename", "classes/ActiveStorage/Filename.html#method-i-base", "", ""],
  ]

  def test_entries
    assert_equal 1, entries(INDEX, "has_many").size
    assert_equal %w[ActiveRecord::Core::ClassMethods ActiveRecord::FinderMethods], entries(INDEX, "find").map { |row| row[1] }
    assert_equal ["classes/ActiveRecord/Base.html"], entries(INDEX, "ActiveRecord::Base").map { |row| row[2] }
    assert_equal %w[ActionController::Base ActiveRecord::Base], entries(INDEX, "Base").map { |row| row[0] }
    assert_equal ["classes/ActiveStorage/Filename.html#method-i-base"], entries(INDEX, "base").map { |row| row[2] }
    assert_empty entries(INDEX, "nothing")
  end

  def test_titles
    assert_equal "ActiveRecord::Associations::ClassMethods#has_many", title(INDEX[0])
    assert_equal "ActiveRecord::Base", title(INDEX[3])
    assert_equal "ActiveStorage::Filename#base", title(INDEX[5])
  end
end

class HelpTest < Minitest::Test
  def test_markdown
    html = to_html("Some `code` and a [link](https://example.com).\n\n* **Bold** item\n  continued\n* Second <item>\n")
    assert_equal "<p>Some <code>code</code> and a <a href=\"https://example.com\">link</a>.</p>\n<ul>\n<li><strong>Bold</strong> item continued</li>\n<li>Second &lt;item&gt;</li>\n</ul>", html
  end
end

class PartialTest < Minitest::Test
  def test_inline_partials_round_trip
    document = File.read(ENV["TM_FILEPATH"])
    expanded = toggle_inline_partials(document)
    assert_equal <<~ERB, expanded
      <h1>Posts</h1>
      <%= render "form" %>
      <!-- [[ Partial 'app/views/posts/_form.html.erb' Begin ]] -->
      <form>
      </form>
      <!-- [[ Partial 'app/views/posts/_form.html.erb' End ]] -->
      <%= render @posts %>
      <!-- [[ Partial 'app/views/posts/_post.html.erb' Begin ]] -->
      <p><%= post.title %></p>
      <!-- [[ Partial 'app/views/posts/_post.html.erb' End ]] -->
    ERB

    edited = expanded.sub("<form>\n", "<form class=\"post\">\n")
    assert_equal document, toggle_inline_partials(edited)
    assert_equal "<form class=\"post\">\n</form>\n", File.read(File.join(ROOT_DIR, "app/views/posts/_form.html.erb"))
  ensure
    File.write(File.join(ROOT_DIR, "app/views/posts/_form.html.erb"), "<form>\n</form>\n")
  end

  def test_view_without_partials
    assert_nil toggle_inline_partials("<h1>Hello</h1>\n")
  end
end
