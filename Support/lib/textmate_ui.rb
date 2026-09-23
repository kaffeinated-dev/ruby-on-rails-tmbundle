# Dialogs, opening files, and output for commands written in Ruby, using
# $DIALOG and $TM_MATE directly. TextMate’s own Ruby support library
# (textmate.rb, ui.rb) cannot be loaded on Apple silicon, as its plist
# extension has no arm64 slice.

module TextMateUI
  module_function

  def exit_discard;               exit 200;                  end
  def exit_insert_text(text);     print text; exit 203;      end
  def exit_show_tool_tip(text);   print text; exit 206;      end

  # Open a file in TextMate, optionally at a line.
  def open(path, line = nil)
    arguments = [ENV["TM_MATE"]]
    arguments += ["--line", line.to_s] if line
    system(*arguments, path, out: File::NULL, err: File::NULL)
  end

  # Show a menu at the caret; «items» are [title, value] pairs, or nil for a
  # separator. Returns the value of the selected item, or nil.
  def menu(items)
    list = items.map { |item| item ? "{ title = #{quote(item[0])}; value = #{quote(item[1])}; }" : "{ separator = 1; }" }
    value(dialog("menu", "--items", "(#{list.join(", ")})"), "value")
  end

  # Ask for confirmation in a warning alert. Returns true when confirmed.
  def confirm(title, message, button)
    value(dialog("alert", "--alertStyle", "warning", "--title", title, "--body", message, "--button1", button, "--button2", "Cancel"), "buttonClicked") == "0"
  end

  # Ask for a string. Returns nil when cancelled.
  def request_string(title, prompt, default, button)
    model = "{ title = #{quote(title)}; prompt = #{quote(prompt)}; string = #{quote(default)}; button1 = #{quote(button)}; button2 = \"Cancel\"; }"
    token = dialog("nib", "--load", "#{ENV['TM_SUPPORT_PATH']}/nibs/RequestString.nib", "--center", "--model", model).strip
    value(dialog("nib", "--modal", "--wait", token, "--dispose", token), "eventInfo.returnArgument")
  end

  def dialog(*arguments)
    IO.popen([ENV["DIALOG"], *arguments], &:read)
  end

  # A value from a property list, or nil when it has no such key.
  def value(plist, key_path)
    result = IO.popen(["/usr/bin/plutil", "-extract", key_path, "raw", "-o", "-", "-"], "r+", err: File::NULL) do |io|
      io.write(plist)
      io.close_write
      io.read
    end
    result = result.chomp("\n") # plutil ends the value with a newline
    $?.success? && !result.empty? ? result : nil
  end

  # Quote a string for an old-style (ASCII) property list.
  def quote(string)
    "\"#{string.to_s.gsub("\\", "\\\\\\\\").gsub('"', '\\"')}\""
  end
end
