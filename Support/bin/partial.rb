# Create Partial From Selection: move the selected part of a view to a new
# partial and render it instead. Without a selection, show the partials
# rendered by the view inline, between markers, for editing; running it again
# writes them back to their files.
#
# Expects RAILS_ROOT and the TM_* variables of a command; the selection, or the
# document when nothing is selected, is read from standard input.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails_navigator"
require "textmate_ui"

UI = TextMateUI
ROOT = ENV["RAILS_ROOT"]
FILE = RailsNavigator::AppFile.new(ROOT, ENV["TM_FILEPATH"].to_s)
INLINE = /^<!-- \[\[ Partial '(.+?)' Begin \]\] -->\n(.*?)<!-- \[\[ Partial '\1' End \]\] -->\n/m

# Replace the inline partials of «document» by writing them back to their files,
# or show the partials it renders inline. Returns the new document.
def toggle_inline_partials(document)
  if document =~ INLINE
    return document.gsub(INLINE) { File.write(File.join(ROOT, $1), $2); "" }
  end
  expanded = false
  result = document.lines.map do |line|
    found, = RailsNavigator::LineReference.new(FILE, line).resolve
    partial = found && found.find { |path| File.basename(path).start_with?("_") }
    next line unless partial
    expanded = true
    content = File.read(File.join(ROOT, partial))
    content += "\n" unless content.end_with?("\n")
    (line.end_with?("\n") ? line : line + "\n") + "<!-- [[ Partial '#{partial}' Begin ]] -->\n#{content}<!-- [[ Partial '#{partial}' End ]] -->\n"
  end
  expanded ? result.join : nil
end

# Write «selection» to a new partial and return the code rendering it.
def create_partial(selection)
  extension = File.basename(FILE.path).sub(/\A[^.]*/, "") # e.g. .html.erb
  directory = File.dirname(FILE.path)
  name = UI.request_string("Create Partial", "Name of the new partial in #{directory} (without _ and #{extension}):", "partial", "Create") || UI.exit_discard
  name = name.strip.sub(/\A_/, "").sub(/#{Regexp.escape(extension)}\z/, "")
  UI.exit_discard if name.empty?
  path = File.join(directory, "_#{name}#{extension}")
  if File.exist?(File.join(ROOT, path))
    UI.confirm("Replace #{path}?", "The partial already exists.", "Replace") || UI.exit_discard
  end

  indentation = selection[/\A[ \t]*/]
  content = selection.lines.map { |line| line.start_with?(indentation) ? line[indentation.size..-1] : line }.join
  content += "\n" unless content.end_with?("\n")
  File.write(File.join(ROOT, path), content)

  # In the views of a controller, its partials are rendered by name.
  reference = FILE.find(:controller) && FILE.views_directory == directory ? name : File.join(directory.sub(%r{\Aapp/views/}, ""), name)
  render = extension.end_with?(".haml") ? "= render \"#{reference}\"" : "<%= render \"#{reference}\" %>"
  indentation + render + (selection.end_with?("\n") ? "\n" : "")
end

if __FILE__ == $0
  UI.exit_show_tool_tip("Create Partial From Selection works in views.") unless FILE.kind == :view
  input = $stdin.read
  if ENV["TM_SELECTED_TEXT"].to_s.empty?
    document = toggle_inline_partials(input) || UI.exit_show_tool_tip("This view renders no partials to show inline.")
    print document
    exit 202 # replace the document
  else
    print create_partial(input)
  end
end
