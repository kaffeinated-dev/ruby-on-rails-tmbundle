# Navigation in a Rails application: related files (controller, model, views,
# tests, …), files referenced on a line, table columns from db/schema.rb, and
# definitions of methods, classes, and associations.
#
# Plain Ruby (2.6 or later) without dependencies besides the bundled Inflector,
# so the navigation commands don’t need to start the application.

require "rails/inflector"

module RailsNavigator
  # A file of a Rails application, with its kind and the names of the resource
  # it belongs to. E.g. app/controllers/admin/posts_controller.rb is the
  # :controller in namespace "admin" with controller name "posts" and model
  # name "post".
  class AppFile
    PATTERNS = [
      [:controller,      %r{\Aapp/controllers/(?:(.+)/)?(\w+)_controller\.rb\z}],
      [:helper,          %r{\Aapp/helpers/(?:(.+)/)?(\w+)_helper\.rb\z}],
      [:mailer,          %r{\Aapp/mailers/(?:(.+)/)?(\w+_mailer)\.rb\z}],
      [:view,            %r{\Aapp/views/(?:(.+)/)?(\w+)/[^/]+\z}],
      [:model,           %r{\Aapp/models/(?!concerns/)(?:(.+)/)?(\w+)\.rb\z}],
      [:controller_test, %r{\Atest/controllers/(?:(.+)/)?(\w+)_controller_test\.rb\z}],
      [:model_test,      %r{\Atest/models/(?:(.+)/)?(\w+)_test\.rb\z}],
      [:fixture,         %r{\Atest/fixtures/(?:(.+)/)?(\w+)\.yml\z}],
      [:javascript,      %r{\Aapp/javascript/controllers/(?:(.+)/)?(\w+)_controller\.js\z}],
      [:stylesheet,      %r{\Aapp/assets/stylesheets/(?:(.+)/)?(\w+)\.(?:css|scss|sass)\z}],
    ]
    MODEL_KINDS = [:model, :model_test, :fixture]

    attr_reader :root, :path, :kind, :namespace, :controller_name, :model_name

    def initialize(root, path)
      @root = root
      @path = path.start_with?("/") ? path.sub(%r{\A#{Regexp.escape(root)}/}, "") : path
      PATTERNS.each do |kind, pattern|
        next unless @path =~ pattern
        @kind, @namespace, name = kind, $1, $2
        if MODEL_KINDS.include?(kind)
          @model_name = kind == :fixture ? Inflector.singularize(name) : name
          @controller_name = Inflector.pluralize(@model_name)
        else
          @controller_name = name
          @model_name = Inflector.singularize(name.sub(/_mailer\z/, ""))
        end
        break
      end
    end

    def absolute(path)
      File.join(root, path)
    end

    def exist?(path)
      File.exist?(absolute(path))
    end

    # Relative paths of the file of the given kind, most likely first. The
    # first one is where a missing file is created.
    def candidates(kind)
      return [] unless @kind
      controllers = [controller_name, Inflector.pluralize(model_name), model_name].uniq
      models = [model_name, Inflector.singularize(controller_name)].uniq
      paths = case kind
              when :controller      then in_namespaces("app/controllers", controllers.map { |n| "#{n}_controller.rb" })
              when :helper          then in_namespaces("app/helpers", controllers.map { |n| "#{n}_helper.rb" })
              when :model           then in_namespaces("app/models", models.map { |n| "#{n}.rb" })
              when :controller_test then in_namespaces("test/controllers", controllers.map { |n| "#{n}_controller_test.rb" })
              when :model_test      then in_namespaces("test/models", models.map { |n| "#{n}_test.rb" })
              when :fixture         then in_namespaces("test/fixtures", models.map { |n| "#{Inflector.pluralize(n)}.yml" })
              when :javascript      then in_namespaces("app/javascript/controllers", controllers.map { |n| "#{n}_controller.js" }) +
                                           in_namespaces("app/assets/javascripts", controllers.map { |n| "#{n}.js" })
              when :stylesheet      then in_namespaces("app/assets/stylesheets", controllers.product(%w[css scss sass]).map { |n, e| "#{n}.#{e}" })
              else []
              end
      paths.uniq
    end

    # The existing file of the given kind, or nil.
    def find(kind)
      candidates(kind).find { |path| exist?(path) }
    end

    # The directory with the views of this controller or mailer.
    def views_directory
      owner = kind == :mailer ? controller_name : (find(:controller) || candidates(:controller).first)
      return nil unless owner
      name = kind == :mailer ? controller_name : File.basename(owner, "_controller.rb")
      namespace_of_owner = kind == :mailer ? namespace : owner[%r{\Aapp/controllers/(.+)/[^/]+\z}, 1]
      File.join(*["app/views", namespace_of_owner, name].compact)
    end

    # Views of an action, HTML first; all views of the controller without an action.
    def views(action = nil)
      directory = views_directory or return []
      pattern = action ? "#{action}.*" : "*"
      Dir.glob(File.join(absolute(directory), pattern)).sort_by { |f| [File.basename(f).include?(".html.") ? 0 : 1, f] }.map { |f| f.sub("#{root}/", "") }
    end

    # The controller or mailer of a view.
    def view_owner
      return nil unless kind == :view
      mailer = File.join(*["app/mailers", namespace, "#{controller_name}.rb"].compact)
      exist?(mailer) ? mailer : (find(:controller) || candidates(:controller).first)
    end

    # The implementation of a test, or the test of an implementation, for files
    # under app/ and lib/: app/jobs/export_job.rb ↔ test/jobs/export_job_test.rb.
    def counterpart
      case path
      when %r{\Atest/lib/(.+)_test\.rb\z} then "lib/#{$1}.rb"
      when %r{\Atest/(.+)_test\.rb\z}     then "app/#{$1}.rb"
      when %r{\Aapp/(.+)\.rb\z}           then "test/#{$1}_test.rb"
      when %r{\Alib/(.+)\.rb\z}           then "test/lib/#{$1}_test.rb"
      end
    end

    private

    def in_namespaces(directory, names)
      [namespace, nil].uniq.flat_map { |ns| names.map { |n| File.join(*[directory, ns, n].compact) } }
    end
  end

  # The name of the method whose definition precedes «line» (1-based), e.g.
  # the controller action the caret is in.
  def self.method_at(source, line)
    source.lines.first([line.to_i, 1].max).reverse_each do |text|
      return $1 if text =~ /^\s*def\s+(?:self\.)?([a-z_]\w*[?!]?)/
    end
    nil
  end

  # The line number (1-based) of the definition of «name» in «file», or nil.
  def self.line_of_method(file, name)
    return nil unless File.file?(file)
    File.foreach(file).with_index(1) { |text, i| return i if text =~ /^\s*def\s+(?:self\.)?#{Regexp.escape(name)}(?=[\s(;]|$)/ }
    nil
  end

  # Source code for a new file of the given kind, e.g. a model or test.
  def self.template_for(path)
    constant = lambda do |p, strip|
      Inflector.camelize(p.sub(strip, "").sub(/\.rb\z/, ""))
    end
    case path
    when %r{\Aapp/models/}      then "class #{constant[path, 'app/models/']} < ApplicationRecord\nend\n"
    when %r{\Aapp/controllers/} then "class #{constant[path, 'app/controllers/']} < ApplicationController\nend\n"
    when %r{\Aapp/helpers/}     then "module #{constant[path, 'app/helpers/']}\nend\n"
    when %r{\Aapp/jobs/}        then "class #{constant[path, 'app/jobs/']} < ApplicationJob\n  def perform\n  end\nend\n"
    when %r{\Aapp/mailers/}     then "class #{constant[path, 'app/mailers/']} < ApplicationMailer\nend\n"
    when %r{\A(?:app|lib)/.+\.rb\z} then "class #{constant[path, %r{\A(?:app/\w+|lib)/}]}\nend\n"
    when %r{\Atest/(\w+)/.+_test\.rb\z}
      superclass = { "controllers" => "ActionDispatch::IntegrationTest", "integration" => "ActionDispatch::IntegrationTest",
                     "helpers" => "ActionView::TestCase", "mailers" => "ActionMailer::TestCase", "jobs" => "ActiveJob::TestCase",
                     "system" => "ApplicationSystemTestCase" }.fetch($1, "ActiveSupport::TestCase")
      "require \"test_helper\"\n\nclass #{constant[path, %r{\Atest/(?:lib|\w+)/}]} < #{superclass}\nend\n"
    when %r{\Atest/fixtures/} then "# Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html\n"
    else ""
    end
  end

  # ===================
  # = File on a line =
  # ===================

  # Paths (relative to the root) referenced by a line: render, layout, asset
  # tags, script and link tags, and require_relative. Each candidate list is
  # tried in order; the result is [existing files, fallback to create].
  class LineReference
    VIEW_GLOB = ".*"

    def initialize(app_file, line, column = nil)
      @file, @line, @column = app_file, line, column
    end

    # [[path, …] of existing files, or nil] and a path to offer creating.
    def resolve
      case @line
      when /\brender\b(.*)/                           then render($1)
      when /\blayout\s*\(?\s*["':](\w+)/              then views_matching("app/views/layouts/#{$1}")
      when /\b(?:stylesheet_link_tag)\b(.*)/          then assets($1, %w[app/assets/stylesheets app/assets/builds public public/stylesheets], %w[.css .scss .sass])
      when /\b(?:javascript_include_tag|javascript_import_module_tag)\b(.*)/ then assets($1, %w[app/javascript app/assets/javascripts app/assets/builds public public/javascripts], %w[.js])
      when /\bimage_tag\b(.*)/                        then assets($1, %w[app/assets/images public], [""])
      when /<script[^>]+src=["']\/?([^"'?]+)/, /<link[^>]+href=["']\/?([^"'?]+)/ then existing([File.join("public", $1)])
      when /\brequire_relative\s*\(?\s*["']([^"']+)/  then relative($1)
      else [nil, nil]
      end
    end

    private

    def existing(paths)
      found = paths.select { |p| File.file?(@file.absolute(p)) }
      [found.empty? ? nil : found, nil]
    end

    def views_matching(base)
      found = Dir.glob(@file.absolute(base) + VIEW_GLOB).sort_by { |f| [f.include?(".html.") ? 0 : 1, f] }.map { |f| f.sub("#{@file.root}/", "") }
      [found.empty? ? nil : found, "#{base}.html.erb"]
    end

    # The directory relative template and partial names are looked up in.
    def view_directory
      @file.kind == :view ? File.dirname(@file.path) : @file.views_directory
    end

    def render(arguments)
      arguments = arguments.sub(/-?%>.*\z/, "").strip.sub(/\A\(\s*/, "")
      collection = arguments[/\A@?([a-z_]\w*)(?=\s*(?:,|\)|\z))/, 1]
      if collection && arguments !~ /\A\w+:/
        # render @posts, render post → app/views/posts/_post
        model = Inflector.singularize(collection)
        return views_matching("app/views/#{Inflector.pluralize(model)}/_#{model}")
      end
      partial = arguments =~ /\bpartial:\s*["':]([\w\/]+)/ || arguments =~ /:partial\s*=>\s*["']([\w\/]+)/
      name = partial ? $1 : arguments[/(?:template:|action:|:action\s*=>|\A\s*\(?)\s*["':]([\w\/]+)/, 1]
      return [nil, nil] unless name
      # In views and helpers a plain name is a partial, in controllers a template.
      partial ||= @file.kind != :controller && arguments !~ /\b(?:template|action):/
      directory, base = name.include?("/") ? [File.join("app/views", File.dirname(name)), File.basename(name)] : [view_directory, name]
      return [nil, nil] unless directory
      views_matching(File.join(directory, partial ? "_#{base}" : base))
    end

    # Asset names: the string or symbol arguments, nearest to the column first.
    def assets(arguments, directories, extensions)
      names = arguments.scan(/["']([^"']+)["']|:(\w+)/).map { |s, sym| s || sym }.reject { |n| n.include?("://") || n =~ /\A(?:data|all|defer|nonce|async|media|type)\z/ }
      paths = names.flat_map do |name|
        name = name.sub(%r{\A/}, "")
        directories.flat_map { |d| extensions.map { |e| File.join(d, name.end_with?(e) ? name : name + e) } }
      end
      existing(paths)
    end

    def relative(name)
      base = File.join(File.dirname(@file.path), name)
      existing([base.end_with?(".rb") ? base : "#{base}.rb"])
    end
  end

  # ==========
  # = Schema =
  # ==========

  Column = Struct.new(:name, :type, :options)

  # Tables and their columns from db/schema.rb: { "posts" => [Column, …] }.
  def self.schema(root)
    file = File.join(root, "db", "schema.rb")
    return nil unless File.file?(file)
    tables, current = {}, nil
    File.foreach(file) do |line|
      if line =~ /^\s*create_table\s+["']([\w.]+)["'](.*?)\s+do\b/
        name, options = $1, $2
        current = tables[name] = []
        unless options =~ /\bid:\s*false/
          type = options[/\bid:\s*:(\w+)/, 1] || "bigint"
          key = options[/\bprimary_key:\s*["':](\w+)/, 1] || "id"
          current << Column.new(key, type, "primary key")
        end
      elsif current && line =~ /^\s*t\.(\w+)\s+["'](\w+)["'](?:,\s*(.*?))?\s*$/
        next if $1 == "index" || $1 == "check_constraint"
        current << Column.new($2, $1, $3.to_s)
      elsif line =~ /^\s*end\b/
        current = nil
      end
    end
    tables
  end

  # The table of a model name or class (e.g. "user", "Admin::User", "@users"),
  # using ‘self.table_name’ from its model when set.
  def self.table_for(root, name, tables)
    word = name.to_s.sub(/\A[@:]+/, "")
    underscored = Inflector.underscore(word).sub(/_(?:id|ids)\z/, "")
    singular = Inflector.singularize(underscored)
    model = File.join(root, "app", "models", "#{singular}.rb")
    if File.file?(model) && File.read(model) =~ /self\.table_name\s*=\s*["':](\w+)/
      return $1 if tables.key?($1)
    end
    [Inflector.pluralize(singular).tr("/", "_"), Inflector.pluralize(File.basename(singular)), underscored.tr("/", "_")].find { |t| tables.key?(t) }
  end

  # Association names declared in a model: [[macro, name], …].
  def self.associations(root, name)
    singular = Inflector.singularize(Inflector.underscore(name.to_s.sub(/\A[@:]+/, "")))
    model = File.join(root, "app", "models", "#{singular}.rb")
    return [] unless File.file?(model)
    File.read(model).scan(/^\s*(belongs_to|has_one|has_many|has_and_belongs_to_many|has_one_attached|has_many_attached|has_rich_text)\s+:(\w+)/)
  end

  # ===============
  # = Definitions =
  # ===============

  Definition = Struct.new(:path, :line, :text)

  # Definitions of «term» in app/, lib/, config/, and test/: methods, classes
  # and modules, and associations, scopes, and attributes declared with it.
  def self.definitions(root, term)
    bare = term.sub(/\A[@:]+/, "")
    name = Regexp.escape(bare)
    patterns = [
      /^\s*def\s+(?:self\.)?#{name}(?=[\s(;]|$)/,
      /^\s*(?:class|module)\s+(?:\w+::)*#{name}\b/,
      /^\s*(?:belongs_to|has_one|has_many|has_and_belongs_to_many|scope|enum|attribute|store_accessor|delegate|alias_attribute|has_one_attached|has_many_attached|has_rich_text|attr_(?:reader|writer|accessor))\s+(?:.*,\s*)?:#{name}\b/,
    ]
    # Instance variables: where they are assigned, e.g. in controller actions.
    patterns << /^\s*@#{name}\s*(?:\|\||&&)?=(?!=)/ if term.start_with?("@")
    results = []
    %w[app lib config test].each do |directory|
      Dir.glob(File.join(root, directory, "**", "*.rb")).sort.each do |file|
        next unless File.read(file).include?(bare)
        File.foreach(file).with_index(1) do |text, i|
          results << Definition.new(file.sub("#{root}/", ""), i, text.strip) if patterns.any? { |p| text =~ p }
        end
      end
    end
    # Definitions in app/ first, then lib/, config/, and test/.
    order = %w[app lib config test]
    results.sort_by { |d| [order.index(d.path[%r{\A\w+}]) || 9, d.path, d.line] }
  end
end
