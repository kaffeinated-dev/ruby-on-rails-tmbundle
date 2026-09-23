# Open the Rails API documentation for the word at the caret, looked up in the
# search index of api.rubyonrails.org (downloaded and cached for a week). When
# the word is defined in several places, a menu lets you choose.
#
# Expects the TM_* variables of a command.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "json"
require "uri"
require "fileutils"
require "textmate_ui"

UI = TextMateUI
SITE = "https://api.rubyonrails.org/"
CACHE = File.expand_path("~/Library/Caches/com.macromates.TextMate/Ruby on Rails bundle/search_index.js")

# Rows of [name, namespace, path, parameters, description].
def search_index
  if !File.file?(CACHE) || File.mtime(CACHE) < Time.now - 7 * 24 * 60 * 60
    FileUtils.mkdir_p(File.dirname(CACHE))
    download = "#{CACHE}.download"
    if system("/usr/bin/curl", "-fsSL", "--max-time", "30", "-o", download, "#{SITE}js/search_index.js")
      File.rename(download, CACHE)
    else
      File.delete(download) if File.exist?(download)
    end
  end
  return nil unless File.file?(CACHE)
  source = File.read(CACHE)
  JSON.parse(source[source.index("{")..source.rindex("}")])["index"]["info"]
rescue JSON::ParserError
  nil
end

# The documentation entries for «word»: methods by name (has_many), classes and
# modules by their full name (ActiveRecord::Base) or last part (Base).
def entries(index, word)
  rows = index.select { |row| row[0] == word || row[0].end_with?("::#{word}") }
  rows = index.select { |row| row[0].casecmp?(word) || row[0].downcase.end_with?("::#{word.downcase}") } if rows.empty?
  rows.sort_by { |row| [row[1].to_s, row[0], row[2]] }
end

def title(row)
  name, namespace, path = row
  return name if namespace.to_s.empty?
  separator = path.include?("#method-c-") ? "." : path.include?("#method-") ? "#" : "::"
  "#{namespace}#{separator}#{name}"
end

if __FILE__ == $0
  word = ENV["TM_CURRENT_WORD"].to_s
  line = ENV["TM_CURRENT_LINE"].to_s
  word += $1 if line =~ /\b#{Regexp.escape(word)}([?!])/
  word = $& if word =~ /\A[A-Z]/ && line =~ /(?:\b[A-Z]\w*::)+#{Regexp.escape(word)}\b/ # ActiveRecord::Base
  UI.exit_show_tool_tip("Place the caret on a method or class name.") if word !~ /\A[A-Za-z_][\w:]*[?!]?\z/

  index = search_index or UI.exit_show_tool_tip("Could not download the Rails API search index.")
  rows = entries(index, word)
  url = if rows.empty?
          "https://duckduckgo.com/?q=#{URI.encode_www_form_component("site:api.rubyonrails.org #{word}")}"
        else
          choice = rows.size == 1 ? "0" : UI.menu(rows.first(40).map.with_index { |r, i| [title(r), i.to_s] }) || UI.exit_discard
          SITE + rows[choice.to_i][2]
        end
  system("/usr/bin/open", url)
  UI.exit_discard
end
