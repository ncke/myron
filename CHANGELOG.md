# Changelog

All notable changes to Myron are recorded here, most recent first. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Myron
uses [semantic versioning](https://semver.org/spec/v2.0.0.html). While the
major version is `0`, a minor release may break the public Swift interface or
the language, and a patch release will not.

## [Unreleased]

### Added

- The executable runs a file: `myron script.my` evaluates it and exits. An
  error goes to standard error with the file, line and column, and the exit
  status is non-zero. A leading `#!` line is ignored.
- The executable binds `print`, `write`, `read-line`, `read-character` and
  `read-all` for standard output and standard input, and `exit` to end the
  process with a given status.
- The executable binds `arguments` to the command-line arguments after the
  file, and `source-file` to the file's path. In the REPL they are `()` and
  `nothing`.

### Changed

- The `myron-repl` executable is now `myron`. Run it with no arguments for the
  REPL, as before.
- The REPL writes errors to standard error.

## [0.2.0] — 2026-09-23

Three new data types, a two-way bridge to Swift, and primitives written in
Swift. The public Swift interface has been renamed throughout, so hosts written
against `0.1.0` will need updating — see [Changed](#changed) and
[Removed](#removed).

### Added

- Association lists, with `get`, `get-or`, `put`, `remove`, `has-key?`, `keys`,
  `values` and `key-index`.
- Hashmaps, through `make-hashmap` and `keys-values`. They share the alist
  names above, which resolve on the type of their argument.
- Sets, through `set` and `make-set`, with `insert`, `remove`, `contains?`,
  `union`, `intersection`, `difference`, `symmetric-difference`, `is-subset?`,
  `is-superset?`, `is-strict-subset?`, `is-strict-superset?`, `is-disjoint?`,
  `powerset` and `cartesian-product`. Sets compare by membership.
- Any value can be a hashmap or alist key, or a member of a set.
- `map` and `filter` over a set give back a set.
- The predicates `set?`, `callable?`, `nan?`, `finite?` and `infinite?`.
- `neg`, `degs-to-rads` and `rads-to-degs`, and word forms for arithmetic:
  `add`, `sub`, `mul` and `div`, and `%` as an alias for `mod`.
- The name `nothing` is bound to the `nothing` value, so source can write it
  down.
- Primitives written in Swift. `MyronSession.define` takes a closure of zero to
  six arguments and handles arity checking, namespacing and error reporting.
  An error thrown from the closure arrives as a `hostError` diagnostic.
- Access to a session's environment from Swift through `query`, `set(_:to:)`
  and `names`.
- Swift interoperability. The `MyronValueRepresentable` and
  `MyronValueConvertible` protocols convert between Swift values and
  `MyronValue`, and a host's own types can conform to them.
- `MyronValue` is `Hashable` and can be written as a Swift literal. It gains
  typed accessors (`asInteger`, `asList`, `asSet` and the rest) and throwing
  ones (`requireInteger()`, `require()` and the rest).
- `MyronHashmap` and `MyronSet` as Swift types, with the set algebra available
  directly from Swift.
- `MyronResult` gains `isSuccess`, `asSuccess`, `asFailure` and `isNothing`.
- The error kinds `ambiguousResolution`, `couldNotResolve`,
  `containingEnvironmentNoLongerExists`, `duplicateKeys`, `hostError`,
  `invalidName` and `malformedAlist`.
- A new REPL banner, drawn in colour when the terminal supports it.

### Changed

- Public types carry a `Myron` prefix to stay clear of common names: `Value` is
  now `MyronValue`, `Procedure` is `MyronProcedure`, `Primitive` is
  `MyronPrimitive`, `HigherOrder` is `MyronHigherOrder`, `HigherProbe` is
  `MyronHigherProbe`, and `Location` is `MyronLocation`.
- The package version moves from `Myron.version` to `MyronLanguage.version`.
- The error kind `internalError` is now `` `internal` ``.
- `eq` and `neq` accept values of any type. Values of different types are
  unequal, so `(== 1 1.0)` is `false` where it used to be an error, and
  `nothing` equals itself. Procedures, primitives, sets and hashmaps can be
  compared too.
- The standard library chooses among overloaded primitives by the types of the
  arguments. A call that matches no overload reports `couldNotResolve`, with
  the forms that would have worked.
- Parsing and equality no longer recurse, so deeply nested source or values
  cannot overflow the host thread's stack there.

### Removed

- `Environment` is no longer public.
- The error kind `expectedRightBracket`. An unclosed `(` reports
  `unmatchedParenthesis` instead.
- The error kind `inequatableTypes`, which `eq` no longer needs.

### Fixed

- Calling a procedure after its session has been deallocated now fails with
  `containingEnvironmentNoLongerExists` instead of being undefined.

## [0.1.0] — 2026-09-09

The first release: a small Lisp that can be embedded in a Swift application.

### Added

- S-expression syntax with `quote` and its `'` abbreviation, and `;` comments.
- Nine special forms: `and`, `begin`, `cond`, `define`, `if`, `lambda`, `let`,
  `or` and `quote`.
- Lexically scoped closures, with `and` and `or` short-circuiting.
- Proper tail calls. The evaluator is a CEK machine that keeps its continuation
  on the heap, so recursion depth is bounded by a configurable limit rather
  than by the host thread's stack.
- A standard environment for comparison, predicates, logic, mathematics,
  sequences, lists and strings, plus `map`, `filter`, `reduce`, `all` and
  `any`.
- Sequence primitives that work on both lists and strings.
- Strict numerics: integers and doubles never mix silently, and integer
  overflow is an error.
- Errors are returned as values rather than trapping, and each one carries a
  source location that renders with a caret.
- `MyronSession`, `MyronResult`, `MyronError` and `MyronSessionConfiguration`
  for hosting the interpreter.
- The `myron-repl` executable.

[Unreleased]: https://github.com/ncke/myron/compare/0.2.0...HEAD
[0.2.0]: https://github.com/ncke/myron/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/ncke/myron/releases/tag/0.1.0
