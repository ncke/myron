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
- `sort` and `sort-descending`, which put the elements of a list or set in
  order and give back a list.
- `sortable?`, which says whether `sort` would succeed, and `comparable?`,
  which says whether a value has an ordering.
- `kind`, which names the type of any value as a string.
- The constants `nan` and `infinity`.
- Records, through `make-record-type` and `make-record`. A record type is a
  name and an ordered list of field names, and a record holds one value for
  each field. `get`, `put` and `keys-values` resolve over records, and
  `record-type`, `record-isa?`, `record-type-name`, `record-type-fields` and
  `has-field?` describe them. Naming a field the type does not have is an
  error rather than `nothing`.
- A record type is identified by its name and its fields, in order, so two
  definitions that agree are the same type, and a record made in one session
  is recognised by any other that defines its type the same way.
- `make-hashmap` accepts a record, keying each field by its name as a symbol
  and leaving out any field that holds `nothing`.
- `take-last` and `drop-last`, which work on lists and strings as `take` and
  `drop` do, from the other end.
- `integers` and `integers-between`, which build a list of consecutive
  integers, leaving out the limit. A range that would count downwards is
  empty.
- `zip`, which pairs the elements of two lists and stops at the end of the
  shorter, and `zip-all`, which runs to the end of the longer and pads the
  shorter with `nothing`.
- `flatten`, which opens every nested list in a list, or every nested set in a
  set, at any depth.
- `foldr`, which folds a list or set from the right. It takes the same
  arguments as `reduce` but calls the function with the element first and the
  accumulator second, so `(foldr cons '() xs)` rebuilds `xs`.
- `range` and `range-len`, which extract a stretch of a list or string, given
  its start and either the index it finishes before or its length. Like `take`
  and `drop`, they reject a negative number and are forgiving past the end.
- `apply`, which calls a function with the elements of a list or set as its
  arguments, after any arguments given before it: `(apply + 1 2 '(3 4))` is
  `10`. The last argument must be a list or a set.
- `MyronRecord` and `MyronRecordType` as Swift types. Both are value types; a
  record type is `Sendable`, so a host primitive can capture one. Records are
  built by position or by field name, read with a subscript, `get`, `values`
  and `pairs`, updated with `put`, and checked with `isa(type:)`.
- `MyronValue` gains the accessors `asRecord` and `asRecordType`, and the
  throwing `requireRecord()` and `requireRecordType()`. `MyronRecord` and
  `MyronRecordType` conform to `MyronValueRepresentable` and
  `MyronValueConvertible`.
- `MyronValue.Kind` is `Hashable`.
- The error kinds `duplicateField` and `unexpectedField`.

### Changed

- A `nan` now has a place in the ordering, after every other double, so `lt`,
  `lte`, `gt` and `gte` always give a consistent answer and `sort` puts a `nan`
  at the end. Before, `<` answered `true` whichever side the `nan` was on, and
  `>` answered `false`.
- `min` and `max` follow the same ordering: `min` passes over a `nan` and `max`
  gives one back. Before, the answer depended on where the `nan` was in the
  arguments.
- The `myron-repl` executable is now `myron`. Run it with no arguments for the
  REPL, as before.
- The REPL writes errors to standard error.
- `MyronValue` gains the cases `record` and `recordType`, `MyronValue.Kind`
  gains `record` and `recordType`, and `MyronError.Reason` gains
  `duplicateField` and `unexpectedField`, and `MyronHigherOrder` gains
  `foldr` and `apply`. A host that switches exhaustively over any of these will
  need the new cases.
- `invalidName` is also raised for a record type or field name that Myron
  source could not write, and so can now come back from `eval`.

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
