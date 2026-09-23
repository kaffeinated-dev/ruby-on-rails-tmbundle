# Show the Commands section of the bundle’s README as HTML.

README = File.expand_path("../../README.md", __dir__)

def escape_html(text)
  text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

# The Markdown used in the README: bold, code, and links.
def inline(text)
  escape_html(text)
    .gsub(/`([^`]+)`/) { "<code>#{$1}</code>" }
    .gsub(/\*\*(.+?)\*\*/) { "<strong>#{$1}</strong>" }
    .gsub(/\[([^\]]+)\]\(([^)]+)\)/) { "<a href=\"#{$2}\">#{$1}</a>" }
end

def to_html(markdown)
  markdown.strip.split(/\n{2,}/).map do |block|
    if block.start_with?("* ")
      "<ul>\n" + block.split(/^\* /).reject(&:empty?).map { |item| "<li>#{inline(item.strip.gsub(/\s*\n\s*/, " "))}</li>\n" }.join + "</ul>"
    else
      "<p>#{inline(block.gsub(/\s*\n\s*/, " "))}</p>"
    end
  end.join("\n")
end

if __FILE__ == $0
  commands = File.read(README, encoding: "UTF-8")[/^# Commands\n(.*?)(?=^# |\z)/m, 1].to_s
  puts <<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Ruby on Rails Bundle</title>
<style>
	:root { color-scheme: light dark; }
	body { font: 13px -apple-system, sans-serif; margin: 1.5em; max-width: 50em; line-height: 1.45; }
	h1 { font-size: 1.3em; }
	li { margin-bottom: .5em; }
	code { font: 12px ui-monospace, Menlo, monospace; }
</style>
</head>
<body>
<h1>Ruby on Rails Bundle Commands</h1>
#{to_html(commands)}
</body>
</html>
HTML
end
