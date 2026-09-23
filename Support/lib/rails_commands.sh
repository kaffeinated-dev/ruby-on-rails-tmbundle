# Shared helpers for the Rails commands (migrations, generators).
#
# These only use the shell and the application’s own Ruby. TextMate’s Ruby
# support library (textmate.rb, ui.rb) cannot be loaded on Apple silicon, as
# its plist extension has no arm64 slice.
#
# Commands run in the Rails root with the Ruby version configured for the
# application: via mise when available (set TM_MISE in Preferences → Variables
# to override its location), otherwise with the PATH TextMate provides.

# Print the Rails root: the closest directory with an executable bin/rails,
# starting with the current file’s directory, then the project folder.
rails_root () {
	local start dir
	for start in "${TM_DIRECTORY:-}" "${TM_PROJECT_DIRECTORY:-}"; do
		dir=$start
		while [[ -n "$dir" && "$dir" != / ]]; do
			if [[ -x "$dir/bin/rails" ]]; then
				echo "$dir"
				return 0
			fi
			dir=$(dirname "$dir")
		done
	done
	return 1
}

# Print the path to mise, if installed.
rails_mise () {
	local candidate
	for candidate in "${TM_MISE:-}" "$(command -v mise)" "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
		if [[ -n "$candidate" && -x "$candidate" ]]; then
			echo "$candidate"
			return 0
		fi
	done
	return 1
}

# Set RAILS_ROOT, or show a tool tip and exit when not in a Rails application.
rails_require_root () {
	RAILS_ROOT=$(rails_root) || rails_exit_tool_tip "No Rails application found: there is no bin/rails in the current file’s directory, the project folder, or their parents."
}

# Run a command in RAILS_ROOT with the application’s Ruby.
rails_exec () {
	local mise
	mise=$(rails_mise)
	(
		cd "$RAILS_ROOT" || exit 1
		if [[ -n "$mise" ]]; then
			exec "$mise" exec -- "$@"
		else
			exec "$@"
		fi
	)
}

# Like rails_exec, but without input, so generators can’t wait for an answer.
rails_run () { rails_exec "$@" </dev/null; }

# Run the bundle’s own Ruby scripts: with macOS’s Ruby when available, as it
# starts faster than through mise, otherwise with the application’s Ruby.
rails_ruby () {
	if [[ -x /usr/bin/ruby ]]; then
		/usr/bin/ruby "$@"
	else
		rails_exec ruby "$@"
	fi
}

rails_exit_tool_tip () { printf '%s' "$1"; exit 206; }
rails_exit_discard  () { exit 200; }

# ===========
# = Dialogs =
# ===========

# Quote a string for an old-style (ASCII) property list.
rails_plist_quote () {
	local s=${1//\\/\\\\}
	s=${s//\"/\\\"}
	printf '"%s"' "$s"
}

# Ask for a string: title, prompt, default value, button title.
# Prints the entered string; returns 1 when cancelled.
rails_request_string () {
	local model token result
	model="{ title = $(rails_plist_quote "$1"); prompt = $(rails_plist_quote "$2"); string = $(rails_plist_quote "$3"); button1 = $(rails_plist_quote "${4:-OK}"); button2 = \"Cancel\"; }"
	token=$("$DIALOG" nib --load "$TM_SUPPORT_PATH/nibs/RequestString.nib" --center --model "$model") || return 1
	result=$("$DIALOG" nib --modal --wait "$token" --dispose "$token")
	printf '%s' "$result" | /usr/bin/plutil -extract eventInfo.returnArgument raw -o - - 2>/dev/null
}

# Show a menu at the caret. Arguments are alternating titles and values.
# Prints the value of the selected item; returns 1 when cancelled.
rails_menu () {
	local items="(" result
	while [[ $# -ge 2 ]]; do
		items+="{ title = $(rails_plist_quote "$1"); value = $(rails_plist_quote "$2"); },"
		shift 2
	done
	result=$("$DIALOG" menu --items "$items)")
	printf '%s' "$result" | /usr/bin/plutil -extract value raw -o - - 2>/dev/null
}

# Ask for confirmation in a warning alert: title, message, button title.
# Returns 0 when the button was clicked.
rails_confirm () {
	local result
	result=$("$DIALOG" alert --alertStyle warning --title "$1" --body "$2" --button1 "$3" --button2 Cancel)
	[[ "$(printf '%s' "$result" | /usr/bin/plutil -extract buttonClicked raw -o - - 2>/dev/null)" == 0 ]]
}

# Print the test for the current file, relative to RAILS_ROOT: the file itself
# when it is a test, otherwise its test (app/models/user.rb → test/models/user_test.rb).
rails_test_file () {
	local file=${TM_FILEPATH#"$RAILS_ROOT"/} test
	case "$file" in
		test/*_test.rb) echo "$file"; return 0 ;;
		app/*.rb)       test="test/${file#app/}" ;;
		lib/*.rb)       test="test/$file" ;;
		*)              return 1 ;;
	esac
	test="${test%.rb}_test.rb"
	[[ -f "$RAILS_ROOT/$test" ]] && echo "$test"
}

# Open a file (relative to RAILS_ROOT or absolute) in TextMate.
rails_open () {
	local file=$1
	[[ "$file" == /* ]] || file="$RAILS_ROOT/$file"
	"$TM_MATE" "$file" >/dev/null 2>&1
}

# ===============
# = HTML output =
# ===============

rails_html_escape () { sed -l -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

rails_html_header () {
	cat <<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$(printf '%s' "$1" | rails_html_escape)</title>
<style>
	:root { color-scheme: light dark; }
	body { font: 13px -apple-system, sans-serif; margin: 1.5em; }
	h1 { font-size: 1.3em; margin: 0 0 .2em; }
	.meta { color: GrayText; margin: 0 0 1em; }
	pre { font: 12px ui-monospace, Menlo, monospace; white-space: pre-wrap; margin: 0; }
	.status { margin-top: 1em; font-weight: 600; }
	.success { color: #2e8b35; }
	.failure { color: #d33; }
</style>
</head>
<body>
<h1>$(printf '%s' "$1" | rails_html_escape)</h1>
<p class="meta"><code>$(printf '%s' "$2" | rails_html_escape)</code> in $(printf '%s' "${RAILS_ROOT/#$HOME/~}" | rails_html_escape)</p>
<pre>
HTML
}

rails_html_footer () { # exit code, [message when the exit code is 0 but the command did not succeed]
	if [[ $1 -ne 0 ]]; then
		echo "</pre><p class=\"status failure\">Failed with exit code $1.</p></body></html>"
	elif [[ -n "${2:-}" ]]; then
		echo "</pre><p class=\"status failure\">$2</p></body></html>"
	else
		echo '</pre><p class="status success">Done.</p></body></html>'
	fi
}

# Run bin/rails with the given arguments and stream the output as HTML.
rails_html_task () { # title, bin/rails arguments…
	local title=$1 rc
	shift
	rails_html_header "$title" "bin/rails $*"
	rails_run bin/rails "$@" 2>&1 | rails_html_escape
	rc=${PIPESTATUS[0]}
	rails_html_footer "$rc"
	exit 0
}
