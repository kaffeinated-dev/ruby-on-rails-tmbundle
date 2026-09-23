# Complete a reference to a fixture: the label of a fixture of the referenced
# table, from test/fixtures (or spec/fixtures).
#
#   In fixtures:           author: da   → author: david
#   With «list», in lists: tags: ruby, ra → tags: ruby, rails
#   In tests:              users(:da    → users(:david)
#
# usage: fixture_complete.rb [list] < current line
#
# Expects RAILS_ROOT and the TM_* variables of a command.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails_navigator"
require "textmate_ui"

UI = TextMateUI

# Labels of the fixtures for «reference» (e.g. author, users).
def fixture_labels(root, reference)
  table = Inflector.pluralize(reference)
  file = %w[test spec].map { |dir| File.join(root, dir, "fixtures", "#{table}.yml") }.find { |f| File.file?(f) }
  return nil unless file
  File.read(file).scan(/^([A-Za-z0-9_][\w-]*):[ \t]*(?:#.*)?$/).flatten - %w[DEFAULTS _fixture]
end

# [reference, text typed so far, lambda building the completed line], or nil.
def parse(line, fixture_file, list, caret)
  if fixture_file
    return nil unless line =~ /\A(\s+)([a-z_]+):[ \t]*(.*?)([\w-]*)[ \t]*(\r?\n)?\z/
    indentation, reference, before, typed, newline = $1, $2, $3, $4, $5
    before = "" unless list
    [reference, typed, ->(label) { "#{indentation}#{reference}: #{before}#{label}#{newline}" }]
  else
    calls = line.to_enum(:scan, /\b([a-z_]+)\(:([\w-]*)\)?/).map { Regexp.last_match }
    call = calls.find { |m| m.begin(0) <= caret && caret <= m.end(0) } || calls.last or return nil
    symbol = ->(label) { label =~ /\A\w+\z/ ? ":#{label}" : ":\"#{label}\"" }
    [call[1], call[2], ->(label) { line[0...call.begin(0)] + "#{call[1]}(#{symbol[label]})" + line[call.end(0)..-1] }]
  end
end

if __FILE__ == $0
  line = $stdin.read
  fixture_file = ENV["TM_FILEPATH"].to_s =~ %r{/(test|spec)/fixtures/.+\.yml\z}
  reference, typed, complete = parse(line, fixture_file, ARGV[0] == "list", ENV["TM_LINE_INDEX"].to_i)
  UI.exit_show_tool_tip(fixture_file ? "Type a reference like ‘author: ’ first." : "Type a fixture reference like ‘users(:’ first.") unless reference
  labels = fixture_labels(ENV["RAILS_ROOT"], reference) or UI.exit_show_tool_tip("There are no #{Inflector.pluralize(reference)} fixtures.")
  candidates = labels.select { |label| label.include?(typed) }.sort_by { |label| [label.start_with?(typed) ? 0 : 1, label] }
  UI.exit_show_tool_tip("No #{Inflector.pluralize(reference)} fixture matches ‘#{typed}’.") if candidates.empty?
  label = candidates.size == 1 ? candidates.first : UI.menu(candidates.map { |c| [c, c] }) || UI.exit_discard
  print complete[label]
end
