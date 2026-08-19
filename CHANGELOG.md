# Changelog

This file contains a record of all changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.0] - Unreleased

### Added

- This changelog.
- The gem metadata contains a `homepage_uri`, a `bug_tracker_uri`, and a
  `changelog_uri`. RubyGems shows these links on the gem page.

### Removed

- **Breaking:** Support for Ruby 3.1 and Ruby 3.2. The minimum version is now
  Ruby 3.3.

### Changed

- **Breaking:** These class methods are no longer public. A `protected` or a
  `private` keyword was above each method, but these keywords do not apply to
  `def self.` methods. Thus each method stayed public. Each method is now
  correctly protected or private:

  | Method | New visibility |
  | --- | --- |
  | `JIRA::Base.maybe_nested_attribute` | `protected` |
  | `JIRA::Base.url_with_query_params` | `protected` |
  | `JIRA::Base.hash_to_query_string` | `protected` |
  | `JIRA::Base.query_params_for_single_fetch` | `protected` |
  | `JIRA::Resource::Agile.path_base` | `private` |
  | `JIRA::Resource::Board.path_base` | `private` |
  | `JIRA::Resource::RapidView.path_base` | `private` |
  | `JIRA::Resource::Sprint.agile_path` | `private` |

  If you call one of these methods from outside the gem, Ruby now raises
  `NoMethodError`. This change does not apply to
  `JIRA::Base.query_params_for_search`, which stays public.

- The public `respond_to?` methods on `JIRA::Base`, `JIRA::Resource::Field`, and
  `JIRA::Resource::Issue` are removed. Ruby now supplies `respond_to?`, which
  calls the new `respond_to_missing?` method. If your code calls
  `respond_to?(name)`, the result does not change. If your code calls
  `super` from an overridden `respond_to?` in a subclass, examine it: the
  removed methods ignored the second `include_all` argument, but
  `respond_to_missing?` uses it.
- The `initialize` methods of `JIRA::HttpClient`, `JIRA::OauthClient`, and
  `JIRA::HTTPError` call `super`. If you have a subclass of one of these classes,
  its `initialize` method must also call `super`.
- `JIRA::RequestClient#request` and `JIRA::RequestClient#request_multipart` send
  their arguments with `*`. Before, they used an `args` array. The behavior for
  callers does not change.

### Fixed

- `respond_to?` and `method` did not agree. `JIRA::Base`, `JIRA::HasManyProxy`,
  `JIRA::Resource::Field`, and `JIRA::Resource::Issue` use `method_missing` for
  dynamic attributes, but they did not have a `respond_to_missing?` method. Thus
  `issue.respond_to?(:summary)` gave `true`, but `issue.method(:summary)` raised
  `NameError`. These classes now have `respond_to_missing?`, and `method`,
  `Method#owner`, and code that examines an object all operate correctly.
- `JIRA::HTTPError#to_s` gave the class name, not the error text. The class had
  an `attr_reader :message` that hid the method of `StandardError`, and the
  `initialize` method did not call `super`. Thus `error.message` gave the text
  but `error.to_s` gave `"JIRA::HTTPError"`. The `initialize` method now calls
  `super` with the text, and the two methods agree.
- `JIRA::Resource::Agile#path_base` raised `NoMethodError`. The instance method
  called the private class method with an explicit receiver, which Ruby does not
  permit. This defect was not visible, because only the class methods of `Agile`
  are in use.

### Internal

These changes do not modify the public API.

- These RuboCop cops are enabled again, and all related offenses are corrected:
  `Layout/LineLength`, `Lint/ConstantDefinitionInBlock`, `Lint/EmptyClass`,
  `Lint/IneffectiveAccessModifier`, `Lint/MissingSuper`, `Naming/HeredocDelimiterNaming`,
  `Naming/VariableNumber`, `RSpec/ExpectInHook`, `RSpec/IndexedLet`,
  `RSpec/InstanceVariable`, `RSpec/LeakyConstantDeclaration`,
  `RSpec/MultipleMemoizedHelpers`, `RSpec/NestedGroups`,
  `RSpec/ReceiveMessages`, `RSpec/SpecFilePathFormat`, and
  `Style/MissingRespondToMissing`.
- The JSON test data in `spec/jira/resource/board_spec.rb` is now in
  `spec/mock_responses/board/`. The spec file decreased from 222 lines to 126
  lines.
- Each spec in `spec/integration` has `type: :integration` metadata. You can now
  run only one group of tests: `rspec --tag type:integration` for the
  integration tests, or `rspec --tag ~type:integration` for the unit tests.
- The `before` hooks that used `expect` now use `allow`. A hook that stubs a
  method must not also make an assertion. Where the assertion was necessary, the
  examples now use `have_received`. The example `sends a DELETE request` in
  `spec/jira/base_spec.rb` did not test the DELETE request; it now does.
- The example `gets board configuration for a board` in
  `spec/jira/resource/board_spec.rb` tested only that the result was not nil.
  Thus the example gave a pass with no data. The example now tests the id, the
  name, the type, the location, and the columns.
- The `spec/jira/resource/sprint_spec.rb` file had a `describe 'peristence'`
  group. This group had no `let`, `before`, or `subject` of its own, and its
  name had a spelling error. The group is removed, and its contents moved up one
  level.
- The `spec/jira/resource/jira_picker_suggestions_issue_spec.rb` file has the
  name `issue_picker_suggestions_issue_spec.rb`. The new name agrees with the
  `JIRA::Resource::IssuePickerSuggestionsIssue` class that the spec tests.
- The shared spec fixtures are now in `spec/support/`. This removed a second
  `JIRAResourceDelegation` class.
- A test in `spec/jira/resource/issue_spec.rb` did not test the correct object.
  The example used the `@issue` variable, but no code sets this variable. Thus
  the example tested `nil` and always passed. The example now uses the decorated
  issue, and it tests `JIRA::Resource::Issue` correctly.
- A test in `spec/jira/base_spec.rb` failed for some `--order random` seeds. The
  `nested_collections` examples changed a shared fixture class, but did not put
  back the initial value.

[Unreleased]: https://github.com/sumoheavy/jira-ruby/compare/v4.0.0...HEAD
[4.0.0]: https://github.com/sumoheavy/jira-ruby/compare/v3.2.1...v4.0.0
