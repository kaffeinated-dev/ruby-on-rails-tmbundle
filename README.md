# Installation

You can install this bundle in TextMate by opening the preferences and going to the bundles tab. After installation it will be automatically updated for you.

# General

* [Bundle Styleguide](http://kb.textmate.org/bundle_styleguide) — _before you make changes_
* [Commit Styleguide](http://kb.textmate.org/commit_styleguide) — _before you send a pull request_
* [Writing Bug Reports](http://kb.textmate.org/writing_bug_reports) — _before you report an issue_

# Commands

The commands run `bin/rails` in the Rails application of the current file (the closest directory with `bin/rails`), using the application’s Ruby version: through [mise](https://mise.jdx.dev) when it is installed, otherwise with the `PATH` from TextMate’s Preferences → Variables. If mise is installed somewhere unusual, set `TM_MISE` to its path in Preferences → Variables.

* **Create Migration…** (⌃⇧M): asks for the migration name, optionally followed by columns (`AddEmailToUsers email:string:index`), runs `bin/rails generate migration`, and opens the new migration.
* **Migrate**, **Rollback**, **Redo Last Migration**, **Migrate to Version…**, and **Migration Status** (⌃|): run the corresponding `db:migrate` tasks and show the output in a window.
* **Generate Model from Migration** (⌃|): in a migration that creates a table, runs `bin/rails generate model` with the table’s columns (without creating another migration) and opens the model. Existing files are left untouched.
* **Test All**, **Test Current File**, **Test at Caret**, **Test Models**, **Test Controllers**, **Test Integration**, and **Test System** (⌃\\): run `bin/rails test` for everything, the current file’s test (`app/models/user.rb` → `test/models/user_test.rb`), the test around the caret, or a group of tests.
* **Load Fixtures**, **Load Schema into Database**, **Dump Schema from Database**, and **Prepare Test Database** (⌃|): run the corresponding `db:` tasks. Loading fixtures or the schema into the development database asks for confirmation first.
* **Alternate File** (⌥⌘↓): switches between a controller action and its view, and between a file and its test (`app/models/post.rb` ↔ `test/models/post_test.rb`, `app/jobs/…` ↔ `test/jobs/…`).
* **Go to Controller**, **Model**, **View**, **Helper**, **Controller Test**, **Model Test**, **Fixture**, **JavaScript**, and **Stylesheet** (⌥⇧⌘↓): open the related file of the current resource. Missing files can be created, views ask for their name.
* **File on Current Line** (⌥⌘↑): opens the partial, template, or layout rendered on the current line, the asset of a `stylesheet_link_tag`, `javascript_include_tag`, or `image_tag`, or the file of a `require_relative`.
* **Show DB Schema for Current Class** (⌃⇧⌘S) and **List Columns of Model** (⌥Space): show the columns of the model at the caret from `db/schema.rb`, or insert one of its columns or associations.
* **Jump to Method Definition** (⌃F): opens the definition of the method, class, association, or instance variable at the caret in `app`, `lib`, `config`, or `test`.

The commands only use the shell and the application’s Ruby, as TextMate’s Ruby support library can’t be loaded on Apple silicon.

# Development

Grammar changes are covered by scope tests in `test/syntax`. Each file starts with a `# SYNTAX TEST "source.ruby.rails"` header, and lines with `^` markers assert the scopes of the source line above them (see [vscode-tmgrammar-test](https://github.com/PanAeon/vscode-tmgrammar-test)). Run them with:

```sh
npm install
npm test
```

The command helpers have tests too: `ruby test/commands/model_generator_args_test.rb` and `ruby test/commands/rails_navigator_test.rb`.

The tests use the Ruby and HTML grammars from [textmate/ruby.tmbundle](https://github.com/textmate/ruby.tmbundle) and [textmate/html.tmbundle](https://github.com/textmate/html.tmbundle), pinned in `test/fetch-grammars` to the revisions that TextMate installs.

ERB tests (`*.erb`) use `##` as the assertion prefix, as HTML has no line comments; these lines are plain text to the HTML grammar.

# License

Copyright (c) 2006 syncPEOPLE, LLC.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
