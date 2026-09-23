# Installation

You can install this bundle in TextMate by opening the preferences and going to the bundles tab. After installation it will be automatically updated for you.

# General

* [Bundle Styleguide](http://kb.textmate.org/bundle_styleguide) — _before you make changes_
* [Commit Styleguide](http://kb.textmate.org/commit_styleguide) — _before you send a pull request_
* [Writing Bug Reports](http://kb.textmate.org/writing_bug_reports) — _before you report an issue_

# Commands

The migration commands run `bin/rails` in the Rails application of the current file (the closest directory with `bin/rails`), using the application’s Ruby version: through [mise](https://mise.jdx.dev) when it is installed, otherwise with the `PATH` from TextMate’s Preferences → Variables. If mise is installed somewhere unusual, set `TM_MISE` to its path in Preferences → Variables.

* **Create Migration…** (⌃⇧M): asks for the migration name, optionally followed by columns (`AddEmailToUsers email:string:index`), runs `bin/rails generate migration`, and opens the new migration.
* **Migrate**, **Rollback**, **Redo Last Migration**, **Migrate to Version…**, and **Migration Status** (⌃|): run the corresponding `db:migrate` tasks and show the output in a window.
* **Generate Model from Migration** (⌃|): in a migration that creates a table, runs `bin/rails generate model` with the table’s columns (without creating another migration) and opens the model. Existing files are left untouched.

The commands only use the shell and the application’s Ruby, as TextMate’s Ruby support library can’t be loaded on Apple silicon.

# Development

Grammar changes are covered by scope tests in `test/syntax`. Each file starts with a `# SYNTAX TEST "source.ruby.rails"` header, and lines with `^` markers assert the scopes of the source line above them (see [vscode-tmgrammar-test](https://github.com/PanAeon/vscode-tmgrammar-test)). Run them with:

```sh
npm install
npm test
```

The command helpers have tests too: `ruby test/commands/model_generator_args_test.rb`.

The tests use the Ruby and HTML grammars from [textmate/ruby.tmbundle](https://github.com/textmate/ruby.tmbundle) and [textmate/html.tmbundle](https://github.com/textmate/html.tmbundle), pinned in `test/fetch-grammars` to the revisions that TextMate installs.

ERB tests (`*.erb`) use `##` as the assertion prefix, as HTML has no line comments; these lines are plain text to the HTML grammar.

# License

Copyright (c) 2006 syncPEOPLE, LLC.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
