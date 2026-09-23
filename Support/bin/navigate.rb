# Navigation commands: go to a related file, the file on the current line, the
# schema or columns of a model, or a definition.
#
# usage: ruby navigate.rb alternate | go_to «kind» | file_on_line | schema | columns | definition
#
# Expects RAILS_ROOT and the TM_* variables of a command; the current document
# is read from standard input where needed.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fileutils"
require "rails_navigator"
require "textmate_ui"

UI = TextMateUI
ROOT = ENV["RAILS_ROOT"]
FILE = RailsNavigator::AppFile.new(ROOT, ENV["TM_FILEPATH"].to_s)
LABELS = {
  controller: "controller", model: "model", view: "view", helper: "helper", controller_test: "controller test",
  model_test: "model test", fixture: "fixture", javascript: "JavaScript", stylesheet: "stylesheet",
}

def source
  @source ||= $stdin.read.to_s
end

# Open one of «paths» (relative to the root), asking when there are several.
def open_one(paths, line = nil)
  path = paths.size == 1 ? paths.first : UI.menu(paths.map { |p| [p, p] }) || UI.exit_discard
  UI.open(File.join(ROOT, path), line)
  UI.exit_discard
end

# Offer to create a missing file; views ask for their name.
def create(path, line = nil)
  if path.start_with?("app/views/")
    name = UI.request_string("Create View", "The view does not exist yet. Name of the new view in #{File.dirname(path)}:", File.basename(path), "Create") || UI.exit_discard
    path = File.join(File.dirname(path), name)
  else
    UI.confirm("Create #{path}?", "The file does not exist yet.", "Create") || UI.exit_discard
  end
  absolute = File.join(ROOT, path)
  FileUtils.mkdir_p(File.dirname(absolute))
  File.write(absolute, RailsNavigator.template_for(path)) unless File.exist?(absolute)
  UI.open(absolute, line)
  UI.exit_discard
end

# The views of the action at the caret in a controller or mailer.
def action_views
  action = RailsNavigator.method_at(source, ENV["TM_LINE_NUMBER"])
  [action, action ? FILE.views(action) : []]
end

def go_to(kind)
  UI.exit_show_tool_tip("This file isn’t part of a Rails resource (controller, model, view, …).") unless FILE.kind

  case kind
  when :view
    UI.exit_show_tool_tip("Go to View works in controllers and mailers.") unless [:controller, :mailer].include?(FILE.kind)
    action, views = action_views
    return open_one(views) unless views.empty?
    if action
      create(File.join(FILE.views_directory, "#{action}.html.erb"))
    else
      views = FILE.views
      UI.exit_show_tool_tip("#{FILE.views_directory} has no views.") if views.empty?
      open_one(views)
    end
  when :controller
    if FILE.kind == :view
      owner = FILE.view_owner
      UI.exit_show_tool_tip("There is no controller for #{File.dirname(FILE.path)}.") unless owner && FILE.exist?(owner)
      action = File.basename(FILE.path).split(".").first.sub(/\A_/, "")
      open_one([owner], RailsNavigator.line_of_method(File.join(ROOT, owner), action))
    end
    related(kind)
  else
    related(kind)
  end
end

def related(kind)
  if (found = FILE.find(kind))
    open_one([found])
  elsif [:javascript, :stylesheet].include?(kind) || FILE.kind == :view
    UI.exit_show_tool_tip("There is no #{LABELS[kind]} for #{FILE.path}.")
  else
    create(FILE.candidates(kind).first)
  end
end

# Toggle between related files: controller action ↔ view, implementation ↔ test.
def alternate
  target = case FILE.kind
           when :controller
             _, views = action_views
             return open_one(views) unless views.empty?
             :controller_test
           when :view            then return go_to(:controller)
           when :model           then :model_test
           when :model_test, :fixture then :model
           when :controller_test, :javascript, :stylesheet then :controller
           end
  return related(target) if target

  counterpart = FILE.counterpart or UI.exit_show_tool_tip("This file has no alternate file.")
  FILE.exist?(counterpart) ? open_one([counterpart]) : create(counterpart)
end

def file_on_line
  line = ENV["TM_CURRENT_LINE"].to_s
  found, fallback = RailsNavigator::LineReference.new(FILE, line).resolve
  return open_one(found) if found
  return create(fallback) if fallback && FILE.kind
  UI.exit_show_tool_tip("There is no file to open on this line (render, layout, asset tags, require_relative).")
end

# The model name at the caret (e.g. User, user, @users, user_id), or of the current file.
def model_word
  word = ENV["TM_CURRENT_WORD"].to_s
  before = ENV["TM_CURRENT_LINE"].to_s[0, ENV["TM_LINE_INDEX"].to_i]
  word = $1 if before =~ /([@\w:]+)\.\w*\z/
  word = FILE.model_name.to_s if word !~ /[A-Za-z]/
  word
end

def schema_tables
  RailsNavigator.schema(ROOT) or UI.exit_show_tool_tip("There is no db/schema.rb (run Dump Schema from Database).")
end

def schema
  tables = schema_tables
  word = model_word
  table = RailsNavigator.table_for(ROOT, word, tables) || (FILE.model_name && RailsNavigator.table_for(ROOT, FILE.model_name, tables))
  UI.exit_show_tool_tip("There is no table for ‘#{word}’ in db/schema.rb.") unless table
  columns = tables[table]
  width = columns.map { |c| c.name.size }.max.to_i
  type_width = columns.map { |c| c.type.size }.max.to_i
  UI.exit_show_tool_tip("#{table}\n" + columns.map { |c| "  #{c.name.ljust(width)}  #{c.type.ljust(type_width)}  #{c.options}".rstrip }.join("\n"))
end

# Insert a column or association of the model at the caret, completing the
# name after the dot if one was started.
def columns
  tables = schema_tables
  word = model_word
  table = RailsNavigator.table_for(ROOT, word, tables) or UI.exit_show_tool_tip("There is no table for ‘#{word}’ in db/schema.rb.")
  before = ENV["TM_CURRENT_LINE"].to_s[0, ENV["TM_LINE_INDEX"].to_i]
  prefix = before[/\.(\w*)\z/, 1].to_s
  associations = RailsNavigator.associations(ROOT, word).map { |macro, name| ["#{name}  (#{macro})", name] }
  columns = tables[table].map { |c| ["#{c.name}  (#{c.type})", c.name] }
  items = [associations, columns].map { |group| group.select { |_, name| name.start_with?(prefix) } }.reject(&:empty?)
  UI.exit_show_tool_tip("#{Inflector.camelize(Inflector.singularize(table))} has no column or association starting with ‘#{prefix}’.") if items.empty?
  choice = UI.menu(items.inject { |all, group| all + [nil] + group }) || UI.exit_discard
  UI.exit_insert_text(choice[prefix.size..-1])
end

def definition
  word = ENV["TM_CURRENT_WORD"].to_s
  line = ENV["TM_CURRENT_LINE"].to_s
  word = "@#{word}" if line =~ /@#{Regexp.escape(word)}\b/ && !word.start_with?("@")
  word += $1 if line =~ /\b#{Regexp.escape(word.sub(/\A@/, ""))}([?!])/
  UI.exit_show_tool_tip("Place the caret on a method, class, or association name.") if word.sub(/\A@/, "") !~ /\A[A-Za-z_]\w*[?!]?\z/
  found = RailsNavigator.definitions(ROOT, word)
  UI.exit_show_tool_tip("No definition of ‘#{word}’ found in app, lib, config, or test.") if found.empty?
  return open_definition(found.first) if found.size == 1
  choice = UI.menu(found.first(40).map.with_index { |d, i| ["#{d.path}:#{d.line}  #{d.text[0, 60]}", i.to_s] }) || UI.exit_discard
  open_definition(found[choice.to_i])
end

def open_definition(definition)
  UI.open(File.join(ROOT, definition.path), definition.line)
  UI.exit_discard
end

case ARGV[0]
when "alternate"    then alternate
when "go_to"        then go_to(ARGV[1].to_sym)
when "file_on_line" then file_on_line
when "schema"       then schema
when "columns"      then columns
when "definition"   then definition
else abort "usage: navigate.rb alternate | go_to «kind» | file_on_line | schema | columns | definition"
end
