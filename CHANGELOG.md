# Changelog

This file contains a record of all changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.0] - Unreleased

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

- `JIRA::RequestClient#request` and `JIRA::RequestClient#request_multipart` send
  their arguments with `*`. Before, they used an `args` array. The behavior for
  callers does not change.

### Fixed

- `JIRA::Resource::Agile#path_base` raised `NoMethodError`. The instance method
  called the private class method with an explicit receiver, which Ruby does not
  permit. This defect was not visible, because only the class methods of `Agile`
  are in use.

### Internal

These changes do not modify the public API.

- The `Layout/LineLength`, `Lint/ConstantDefinitionInBlock`, `Lint/EmptyClass`,
  and `Lint/IneffectiveAccessModifier` RuboCop cops are enabled again. All
  related offenses are corrected.
- The shared spec fixtures are now in `spec/support/`. This removed a second
  `JIRAResourceDelegation` class.
- A test in `spec/jira/base_spec.rb` failed for some `--order random` seeds. The
  `nested_collections` examples changed a shared fixture class, but did not put
  back the initial value.

[Unreleased]: https://github.com/sumoheavy/jira-ruby/compare/v4.0.0...HEAD
[4.0.0]: https://github.com/sumoheavy/jira-ruby/compare/v3.2.1...v4.0.0
