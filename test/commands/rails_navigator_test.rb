require "minitest/autorun"
require "tmpdir"
require "fileutils"
$LOAD_PATH.unshift File.expand_path("../../Support/lib", __dir__)
require "rails_navigator"

class RailsNavigatorTest < Minitest::Test
  FILES = {
    "app/controllers/posts_controller.rb" => "class PostsController < ApplicationController\n  def index\n  end\n\n  def show\n    @post = Post.find(params[:id])\n  end\nend\n",
    "app/controllers/admin/users_controller.rb" => "class Admin::UsersController < ApplicationController\nend\n",
    "app/models/post.rb" => "class Post < ApplicationRecord\n  belongs_to :author\n  has_many :comments, dependent: :destroy\n  scope :published, -> { where(published: true) }\n\n  def publish!\n  end\nend\n",
    "app/models/user.rb" => "class User < ApplicationRecord\n  self.table_name = \"accounts\"\nend\n",
    "app/models/person.rb" => "class Person < ApplicationRecord\nend\n",
    "app/helpers/posts_helper.rb" => "module PostsHelper\nend\n",
    "app/mailers/user_mailer.rb" => "class UserMailer < ApplicationMailer\n  def welcome\n  end\nend\n",
    "app/jobs/export_job.rb" => "class ExportJob < ApplicationJob\nend\n",
    "app/views/posts/index.html.erb" => "<%= render @posts %>\n",
    "app/views/posts/show.html.erb" => "",
    "app/views/posts/show.json.jbuilder" => "",
    "app/views/posts/_post.html.erb" => "",
    "app/views/posts/_form.html.erb" => "",
    "app/views/shared/_header.html.erb" => "",
    "app/views/layouts/admin.html.erb" => "",
    "app/views/user_mailer/welcome.html.erb" => "",
    "app/views/admin/users/index.html.erb" => "",
    "app/javascript/controllers/posts_controller.js" => "",
    "app/assets/stylesheets/application.css" => "",
    "app/assets/images/logo.svg" => "",
    "test/models/post_test.rb" => "",
    "test/controllers/posts_controller_test.rb" => "",
    "test/fixtures/posts.yml" => "",
    "test/fixtures/people.yml" => "",
    "lib/tasks/cleanup.rb" => "",
    "db/schema.rb" => <<~RUBY,
      ActiveRecord::Schema[8.1].define(version: 2025_01_01_000000) do
        create_table "posts", force: :cascade do |t|
          t.string "title", null: false
          t.bigint "author_id"
          t.datetime "created_at", null: false
          t.index ["author_id"], name: "index_posts_on_author_id"
        end

        create_table "accounts", id: :uuid, force: :cascade do |t|
          t.string "email"
        end

        create_table "people", force: :cascade do |t|
          t.string "name"
        end
      end
    RUBY
  }

  def setup
    @root = Dir.mktmpdir("rails-navigator")
    FILES.each do |path, content|
      FileUtils.mkdir_p(File.join(@root, File.dirname(path)))
      File.write(File.join(@root, path), content)
    end
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def file(path)
    RailsNavigator::AppFile.new(@root, File.join(@root, path))
  end

  def test_kinds_and_names
    f = file("app/controllers/admin/users_controller.rb")
    assert_equal [:controller, "admin", "users", "user"], [f.kind, f.namespace, f.controller_name, f.model_name]
    f = file("test/fixtures/people.yml")
    assert_equal [:fixture, "people", "person"], [f.kind, f.controller_name, f.model_name]
    assert_nil file("app/models/concerns/taggable.rb").kind
    assert_nil file("config/routes.rb").kind
  end

  def test_related_files
    post = file("app/models/post.rb")
    assert_equal "app/controllers/posts_controller.rb", post.find(:controller)
    assert_equal "test/models/post_test.rb", post.find(:model_test)
    assert_equal "test/fixtures/posts.yml", post.find(:fixture)
    assert_equal "app/helpers/posts_helper.rb", post.find(:helper)
    assert_equal "app/javascript/controllers/posts_controller.js", post.find(:javascript)
    assert_nil post.find(:stylesheet)
    assert_equal "app/models/person.rb", file("test/fixtures/people.yml").find(:model)
    assert_equal "test/controllers/posts_controller_test.rb", file("app/controllers/posts_controller.rb").find(:controller_test)
  end

  def test_namespaced_controller_falls_back_to_model_without_namespace
    users = file("app/controllers/admin/users_controller.rb")
    assert_equal "app/models/user.rb", users.find(:model)
    assert_equal "test/controllers/admin/users_controller_test.rb", users.candidates(:controller_test).first
    assert_equal "app/views/admin/users", users.views_directory
  end

  def test_views
    posts = file("app/controllers/posts_controller.rb")
    assert_equal %w[app/views/posts/show.html.erb app/views/posts/show.json.jbuilder], posts.views("show")
    assert_equal [], posts.views("edit")
    assert_equal "app/views/posts", file("app/models/post.rb").views_directory
    assert_equal "app/views/user_mailer", file("app/mailers/user_mailer.rb").views_directory
    assert_equal "app/mailers/user_mailer.rb", file("app/views/user_mailer/welcome.html.erb").view_owner
    assert_equal "app/controllers/posts_controller.rb", file("app/views/posts/_form.html.erb").view_owner
  end

  def test_counterpart
    assert_equal "test/jobs/export_job_test.rb", file("app/jobs/export_job.rb").counterpart
    assert_equal "app/jobs/export_job.rb", RailsNavigator::AppFile.new(@root, "test/jobs/export_job_test.rb").counterpart
    assert_equal "test/lib/tasks/cleanup_test.rb", file("lib/tasks/cleanup.rb").counterpart
    assert_equal "lib/tasks/cleanup.rb", RailsNavigator::AppFile.new(@root, "test/lib/tasks/cleanup_test.rb").counterpart
  end

  def test_method_at_and_line_of_method
    source = FILES["app/controllers/posts_controller.rb"]
    assert_equal "show", RailsNavigator.method_at(source, 6)
    assert_equal "index", RailsNavigator.method_at(source, 3)
    assert_nil RailsNavigator.method_at(source, 1)
    assert_equal 5, RailsNavigator.line_of_method(File.join(@root, "app/controllers/posts_controller.rb"), "show")
    assert_equal 6, RailsNavigator.line_of_method(File.join(@root, "app/models/post.rb"), "publish!")
  end

  def test_templates
    assert_equal "class Admin::User < ApplicationRecord\nend\n", RailsNavigator.template_for("app/models/admin/user.rb")
    assert_equal "require \"test_helper\"\n\nclass PostsControllerTest < ActionDispatch::IntegrationTest\nend\n", RailsNavigator.template_for("test/controllers/posts_controller_test.rb")
    assert_equal "require \"test_helper\"\n\nclass ExportJobTest < ActiveJob::TestCase\nend\n", RailsNavigator.template_for("test/jobs/export_job_test.rb")
    assert_equal "require \"test_helper\"\n\nclass Tasks::CleanupTest < ActiveSupport::TestCase\nend\n", RailsNavigator.template_for("test/lib/tasks/cleanup_test.rb")
    assert_equal "module PostsHelper\nend\n", RailsNavigator.template_for("app/helpers/posts_helper.rb")
    assert_equal "class Checkout\nend\n", RailsNavigator.template_for("app/services/checkout.rb")
    assert_equal "class Payments::Refund\nend\n", RailsNavigator.template_for("app/services/payments/refund.rb")
  end

  def reference(path, line)
    RailsNavigator::LineReference.new(file(path), line).resolve
  end

  def test_render_references
    view = "app/views/posts/index.html.erb"
    assert_equal [["app/views/posts/_post.html.erb"], "app/views/posts/_post.html.erb"], reference(view, "<%= render @posts %>")
    assert_equal [["app/views/posts/_form.html.erb"], "app/views/posts/_form.html.erb"], reference(view, '<%= render "form", post: @post %>')
    assert_equal [["app/views/shared/_header.html.erb"], "app/views/shared/_header.html.erb"], reference(view, '<%= render partial: "shared/header" %>')
    assert_equal [nil, "app/views/posts/_sidebar.html.erb"], reference(view, '<%= render "sidebar" %>')
    controller = "app/controllers/posts_controller.rb"
    assert_equal [%w[app/views/posts/show.html.erb app/views/posts/show.json.jbuilder], "app/views/posts/show.html.erb"], reference(controller, "render :show, status: :ok")
    assert_equal [nil, nil], reference(controller, "render json: @post")
  end

  def test_other_references
    view = "app/views/posts/index.html.erb"
    assert_equal [["app/views/layouts/admin.html.erb"], "app/views/layouts/admin.html.erb"], reference("app/controllers/posts_controller.rb", 'layout "admin"')
    assert_equal [["app/assets/stylesheets/application.css"], nil], reference(view, '<%= stylesheet_link_tag :application, "data-turbo-track": "reload" %>')
    assert_equal [["app/assets/images/logo.svg"], nil], reference(view, '<%= image_tag "logo.svg", alt: "Logo" %>')
    assert_equal [["lib/tasks/cleanup.rb"], nil], RailsNavigator::LineReference.new(file("lib/tasks/cleanup.rb"), 'require_relative "cleanup"').resolve
    assert_equal [nil, nil], reference(view, "<p>Hello</p>")
  end

  def test_schema
    tables = RailsNavigator.schema(@root)
    assert_equal %w[posts accounts people], tables.keys
    assert_equal [%w[id bigint], %w[title string], %w[author_id bigint], %w[created_at datetime]], tables["posts"].map { |c| [c.name, c.type] }
    assert_equal "null: false", tables["posts"][1].options
    assert_equal %w[uuid string], tables["accounts"].map(&:type)
  end

  def test_table_for
    tables = RailsNavigator.schema(@root)
    assert_equal "posts", RailsNavigator.table_for(@root, "Post", tables)
    assert_equal "posts", RailsNavigator.table_for(@root, "@posts", tables)
    assert_equal "posts", RailsNavigator.table_for(@root, "post_id", tables)
    assert_equal "people", RailsNavigator.table_for(@root, "person", tables)
    assert_equal "accounts", RailsNavigator.table_for(@root, "User", tables)
    assert_nil RailsNavigator.table_for(@root, "Comment", tables)
  end

  def test_associations
    assert_equal [%w[belongs_to author], %w[has_many comments]], RailsNavigator.associations(@root, "@post")
    assert_equal [], RailsNavigator.associations(@root, "Missing")
  end

  def test_definitions
    assert_equal [["app/models/post.rb", 6]], RailsNavigator.definitions(@root, "publish!").map { |d| [d.path, d.line] }
    assert_equal [["app/models/post.rb", 4]], RailsNavigator.definitions(@root, "published").map { |d| [d.path, d.line] }
    assert_equal [["app/models/post.rb", 3]], RailsNavigator.definitions(@root, "comments").map { |d| [d.path, d.line] }
    assert_equal [["app/controllers/posts_controller.rb", 1]], RailsNavigator.definitions(@root, "PostsController").map { |d| [d.path, d.line] }
    assert_equal [["app/controllers/posts_controller.rb", 6]], RailsNavigator.definitions(@root, "@post").map { |d| [d.path, d.line] }
    assert_equal [], RailsNavigator.definitions(@root, "nothing_here")
  end
end
