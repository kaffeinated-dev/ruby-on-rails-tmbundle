require "minitest/autorun"
require "cgi"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

# Runs the Autocomplete Routes command (bash) with a fake $DIALOG, a routes
# cache in place of bin/rails runner, and a fake Language Server bundle.
class AutocompleteRoutesTest < Minitest::Test
  BUNDLE = File.expand_path("../..", __dir__)
  COMMAND = CGI.unescapeHTML(File.read(File.join(BUNDLE, "Commands/Autocomplete Routes.tmCommand"), encoding: "UTF-8")[%r{<key>command</key>\s*<string>(.*?)</string>}m, 1])

  LANGUAGE_SERVER_COMPLETIONS = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <array>
    \t<dict>
    \t\t<key>display</key>
    \t\t<string>post_params</string>
    \t\t<key>match</key>
    \t\t<string>post_params</string>
    \t</dict>
    </array>
    </plist>
  XML

  def setup
    @dir = Dir.mktmpdir
    @app = File.join(@dir, "app")
    @tmp = File.join(@dir, "tmp")
    FileUtils.mkdir_p([File.join(@app, "bin"), File.join(@app, "config"), @tmp])
    File.write(File.join(@app, "bin/rails"), "#!/bin/sh\nexit 1\n")
    File.chmod(0o755, File.join(@app, "bin/rails"))
    File.write(File.join(@app, "config/routes.rb"), "")
    File.utime(Time.now - 60, Time.now - 60, File.join(@app, "config/routes.rb"))

    @dialog = File.join(@dir, "dialog")
    File.write(@dialog, "#!/bin/bash\nprintf '%s\\n' \"$@\" >> '#{@dialog}.log'\n")
    File.chmod(0o755, @dialog)

    @language_server = File.join(@dir, "Language Server/Support")
    FileUtils.mkdir_p(File.join(@language_server, "bin"))
    File.write(File.join(@language_server, "bin/completions"), "#!/bin/bash\ncat <<'XML'\n#{LANGUAGE_SERVER_COMPLETIONS}XML\n")
    File.chmod(0o755, File.join(@language_server, "bin/completions"))
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  # The cache of the routes (named as the command names it with md5, or
  # without, where there is no /sbin/md5).
  def cache_routes(names)
    [Digest::MD5.hexdigest(File.realpath(@app)), Digest::MD5.hexdigest(@app), ""].uniq.each do |hash|
      File.write(File.join(@tmp, "textmate-rails-routes-#{hash}.txt"), names.join("\n") + "\n")
    end
  end

  def run_command(language_server: true)
    env = {
      "PATH" => "/usr/bin:/bin:/usr/sbin:/sbin",
      "HOME" => @dir,
      "TMPDIR" => @tmp,
      "TM_BUNDLE_SUPPORT" => File.join(BUNDLE, "Support"),
      "TM_DIRECTORY" => File.realpath(@app),
      "DIALOG" => @dialog,
      "TM_CURRENT_LINE" => "    redirect_to po",
      "TM_LINE_INDEX" => "18",
      "TM_MISE" => "/nonexistent",
    }
    env["TM_LANGUAGE_SERVER_BUNDLE_SUPPORT"] = @language_server if language_server
    output, errors, status = Open3.capture3(env, "/bin/bash", "-c", COMMAND, unsetenv_others: true)
    [status.exitstatus, output + errors.lines.grep_v(/Terminated/).join, File.exist?("#{@dialog}.log") ? File.read("#{@dialog}.log") : ""]
  end

  def test_routes_come_before_the_language_servers_completions
    cache_routes(%w[posts rails_info])
    status, output, dialog = run_command
    assert_equal 200, status, output
    assert_match(/\Apopup\n--suggestions\n/, dialog)
    assert_includes dialog, "<string>posts_path</string></dict><dict><key>display</key><string>posts_url</string></dict>\t<dict>"
    assert_operator dialog.index("posts_url"), :<, dialog.index("post_params")
    refute_includes dialog, "rails_info"
    assert_includes dialog, "\n--alreadyTyped\npo\n--additionalWordCharacters\n_?!\n"
  end

  def test_routes_without_a_language_server
    cache_routes(%w[posts])
    status, _, dialog = run_command(language_server: false)
    assert_equal 200, status
    assert_includes dialog, "<string>posts_path</string>"
    refute_includes dialog, "post_params"
  end

  def test_the_language_servers_completions_when_the_routes_cant_be_listed
    status, output, dialog = run_command
    assert_equal 200, status, output
    assert_includes dialog, "<string>post_params</string>"

    File.delete("#{@dialog}.log")
    status, output, = run_command(language_server: false)
    assert_equal 206, status
    assert_match(/\ACould not list the routes/, output)
  end
end
