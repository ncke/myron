# Changelog

All notable changes to Myron are recorded here, most recent first. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Myron
uses [semantic versioning](https://semver.org/spec/v2.0.0.html). While the
major version is `0`, a minor release may break the public Swift interface or
the language, and a patch release will not.

## [Unreleased]

## [0.3.0] — 2026-10-13

Macros and templates, modules, records, error handling with `try` and `raise`,
and variadic parameters. The executable is now `myron`, and runs scripts and
literate markdown files as well as the REPL. Some of the public Swift interface
has changed: new cases on `MyronValue` and its companions, and `set(_:to:)`
now throws. Hosts written against `0.2.0` may need updating — see
[Changed](#changed).

### Added

- The executable runs files: `myron --load one.my --load two.my` evaluates each
  in turn, in one environment, and exits. An error goes to standard error with
  the file, line and column, stops the run, and the exit status is non-zero. A
  leading `#!` line is ignored, and `#!/usr/bin/env -S myron --load` makes a
  script executable.
- `myron --repl` starts the REPL, after loading any files given with `--load`.
  With neither, `myron` prints its usage and fails.
- The executable binds `load`, which evaluates a file into the session from
  inside a program and gives back the value of its last form.
- Literate Myron. A `.md` or `.markdown` file, given to `--load` or `load`, is
  a markdown document whose fenced `lisp` and `myron` blocks are the program,
  and a block marked `ignore` is left out. Errors report the line and column in
  the document. The blocks share one environment, and a block marked
  `reset-environment` starts a clean one.
- `myron --show file` evaluates a file a form at a time and writes each form's
  place, source and result, carrying on past a failing form.
- `MyronSession.evalEach`, which evaluates each top-level form in turn and gives
  back every result, as a `MyronFormResult` with the form's location. A failing
  form does not stop the ones after it. Optional `willEvaluate` and
  `didEvaluate` closures report on each form as it is evaluated.
- The executable binds `print`, `write`, `read-line`, `read-character` and
  `read-all` for standard output and standard input, and `exit` to end the
  process with a given status.
- The executable binds `arguments` to the command-line arguments: everything
  from the first item that is not an option, or after `--`.
- `print` and `write` take any number of values and write them one after
  another.
- `MyronSession.define(_:arity:body:)`, which defines a host primitive that
  takes its arguments as an array, checked against the given arity.
- Every `MyronSession.define` takes an optional signature, such as
  `"({integer} {string}[...])"`, naming the kinds of argument a host primitive
  expects. A term is a set of kinds in braces, or `{any}`, with an optional
  count — `[2]`, `[2...]`, `[2...3]`, `[...2]` or `[...]` — and a `*` before
  the count requires its arguments to share a kind. The signature must accept
  exactly the arguments the body does, and `define` throws if it can't be
  parsed or disagrees. The kinds are not yet checked when the primitive is
  called.
- `MyronSignature`, the public form of a signature. It parses the string
  syntax, gives it back in a standard spelling as its `description`, and gives
  the fewest and most arguments it accepts as its `arity`.
- `MyronError.Reason.malformedSignature`, for a signature that can't be parsed
  or that disagrees with the arity of a host primitive's body.
- `MyronValue.Kind` conforms to `CaseIterable`.
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
- Error messages can end with hints: informal advice from the place the error
  was raised, such as which conversion would let two numbers be compared. One
  hint follows the caret as `HINT:`, several as a `HINTS:` list. Hints are part
  of the message only, so the terse error style shows none.
- `MyronError` is `Equatable` and `Hashable`, comparing its reason, location and
  message. `MyronError.Reason` and `MyronError.IntegerExpectation` are
  `Hashable`.
- The error kinds `duplicateField` and `unexpectedField`.
- `raise`, which raises a string as an error, and the special form `try`,
  written `(try handler (body …))`, which evaluates its bodies and, if one
  raises, calls the handler with the message and yields its result instead.
  The handler is only evaluated when something raises. Only errors from `raise`
  are caught; the interpreter's own errors pass through. An uncaught raise
  fails with the new error kind `raised`.
- `split-all` and `split-once`, which split a string at a separator string:
  at every occurrence, keeping empty fields, or at the first only, into the
  parts before and after. An empty separator raises the new error kind
  `cannotBeEmpty`.
- `find-first`, which gives the index of the first occurrence of one string in
  another, counted in characters as `nth` and `range` count them, or `nothing`.
- `Substring` conforms to `MyronValueRepresentable` and `MyronValueConvertible`,
  as a string.
- The predicate `something?`, the negation of `nothing?`.
- Modules. The special form `module`, written `(module name (export …) body …)`,
  evaluates its bodies in a scope of their own inside the current one and binds
  `name` to a module holding the exported values. Each export must be defined
  by the module itself, by `define` or by `import`, and one that is missing is
  reported with the module's name.
- The special form `import`, written `(import module …)`, which binds each
  module's exports in the current environment, where a `define` would bind
  them, and gives back a define marker for each name bound.
- Qualified names. A symbol that is not bound as it stands, and has dots in it,
  is looked up as a path through modules: `geo.area` is the export `area` of the
  module `geo`, and `outer.inner.x` walks through a nested module. A name the
  module does not export fails with a hint naming the module. `query` from Swift
  understands qualified names too.
- `MyronModule`, the type of a module, with its `name`, its sorted `exports`
  and a subscript for reading one. It is `Equatable` and `Hashable`, and
  conforms to `MyronValueRepresentable` and `MyronValueConvertible`.
  `MyronValue` gains `asModule` and `requireModule()`, and `kind` names a
  module `"module"`.
- The predicate `module?`, and `exports?`, which asks whether a module exports
  a name, or every name in a list. Names may be symbols or strings.
- Calling a symbol, directly or through `map`, `apply` and the other
  higher-order functions, fails with a hint when the symbol names a function
  where the call is made, since it was most likely quoted by mistake:
  `('f 1)` suggests dropping the quote from `'f`.
- Variadic parameters. A parameter written with a trailing `...`, as in
  `(lambda (a xs...) …)` or `(define (f xs...) …)`, collects the arguments the
  other parameters leave over into a list, bound as `xs`. It may appear once,
  in any position, and calling with too few arguments for the rest fails with
  `unexpectedArity` and an `.atLeast` expectation. A second variadic parameter,
  or a bare `...`, fails with the new `unexpectedVariadicParameter`.
- Writing a variadic parameter's dots in the body, as in `(length xs...)`, fails
  as an unrecognised symbol with a hint to write `xs`, or to use `apply` to pass
  its elements as separate arguments. Before, it was read as a qualified name
  and failed with a confusing type error about modules.
- Macros. The special form `defmacro`, written `(defmacro (name param …) body
  …)`, binds a macro, with parameters that follow the rules for a procedure's.
  When a call's head evaluates to a macro, its arguments are not evaluated but
  passed as data, as `quote` gives them. The macro's bodies run in the
  environment it was written in, and their result is turned back into code and
  evaluated in place of the call, in the call's environment and in its tail
  position. A call is expanded each time it is evaluated, and expansions are not
  hygienic. A macro can be exported from a module and reached by a qualified
  name, but it is not callable, so `map` and `apply` reject it.
- `MyronMacro`, the type of a macro, which compares by identity and conforms to
  `MyronValueConvertible`. `MyronValue` gains `asMacro`, a macro prints as
  `<macro: name>`, and `kind` names it `"macro"`.
- An expansion that holds a value that cannot be written as code, such as a
  procedure or a hashmap, fails with the new `valueIsNotCode`, with a hint
  listing what can be.
- Templates. The special form `quasiquote`, written with a backtick, quotes an
  expression except for its holes: inside it, `,expr` (`(unquote expr)`) is
  evaluated and its value put in its place, and `,@expr`
  (`(unquote-splicing expr)`) is evaluated and the elements of the list it gives
  spliced in, so `` `(a ,x ,@ys) `` builds a list from values. A plain quote
  inside a template is filled in with it, so `` `(a ',x) `` gives
  `(a (quote 5))` when `x` is `5`, which is how a macro puts a value into its
  expansion as quoted data. A template inside a template keeps its own commas
  for when it is evaluated, so a macro can write a macro whose expansion is a
  template. A macro can now write its expansion as a template:
  ``(defmacro (unless test then else) `(if ,test ,else ,then))``.
- A backtick or comma with no expression after it fails to parse with the new
  `expectedExpressionAfterQuasiquote` or `expectedExpressionAfterUnquoting`. A
  comma evaluated outside a template, or a `,@` with no list around it to
  splice into, fails with the new `unexpectedUnquoting` and a hint. Splicing
  anything but a list is an `unexpectedType` error.
- `make-symbol`, which turns a string into the symbol with that name, so a
  macro can build the names it defines, and the predicate `symbol?`. The name
  must be one source could write as a symbol, such as `point-x` or `if`, and
  any other, such as `"two words"` or `"42"`, is an `invalidName` error.
  Whether the symbol can be bound is checked when it is bound.
- `$`, a shorter name for `string`, as `+` is for `add`: `($ "x = " 42)` is
  `"x = 42"`.

### Changed

- `string` takes any number of values and joins their printed forms, so
  `(string "x = " 42)` is `"x = 42"`. With one value it behaves as before, and
  with none it gives `""`.
- A host primitive can call `eval` on its own session. The caller's pending
  work is set aside and picks up where it left off once the nested evaluation
  returns. Before, the nested evaluation discarded it, so the outer program
  ended early with the inner result.
- `MyronSessionConfiguration` gains `maximumEvalDepth`, which bounds how deeply
  evaluations can nest through host primitives. Each level runs on the host
  thread's stack, so past the limit the nested `eval` fails with the new
  `exceededMaximumEvalDepth` rather than overflowing the thread. The default is
  `8`, and the initialiser's parameter defaults to it.
- A `nan` now has a place in the ordering, after every other double, so `lt`,
  `lte`, `gt` and `gte` always give a consistent answer and `sort` puts a `nan`
  at the end. Before, `<` answered `true` whichever side the `nan` was on, and
  `>` answered `false`.
- `min` and `max` follow the same ordering: `min` passes over a `nan` and `max`
  gives one back. Before, the answer depended on where the `nan` was in the
  arguments.
- The `myron-repl` executable is now `myron`, and starts the REPL with
  `--repl`.
- The REPL writes errors to standard error.
- `MyronValue` gains the cases `record`, `recordType`, `module` and `macro`,
  `MyronValue.Kind` gains `record`, `recordType`, `module` and `macro`,
  `MyronError.Reason` gains `duplicateField`, `unexpectedField`, `raised`,
  `cannotBeEmpty`, `unexpectedVariadicParameter`, `duplicateName`,
  `valueIsNotCode`, `expectedExpressionAfterQuasiquote`,
  `expectedExpressionAfterUnquoting`, `unexpectedUnquoting`,
  `malformedSignature` and `exceededMaximumEvalDepth`, and
  `MyronHigherOrder` gains `foldr` and `apply`. A host that switches
  exhaustively over any of these will need the new cases.
- `try`, `module`, `import`, `defmacro` and `quasiquote` are special forms, and
  no special form's name can be bound any more. A host's `define`, and
  `define`, `let`, `defmacro` and parameter lists in source, all reject one with
  `invalidName` and a hint. Before, source could bind one, as in
  `(define if 3)`, to no effect: `if` still branched.
- A backtick or comma at the start of a token is read as a template or an
  unquote, so a symbol can no longer start with either. One later in a symbol,
  as in `a,b`, is unchanged. `unquote` and `unquote-splicing` are reserved
  names, like the special forms. A plain quote still never evaluates anything,
  so `'(a ,b)` is the list `(a (unquote b))`.
- A template is filled in on the interpreter's own stack, so each level of it
  counts towards `maximumStackDepth` while an unquote inside it is evaluated.
- `nothing` is a literal, like `true` and `false`, rather than a name bound in
  the standard environment. It can no longer be bound or rebound, so a macro's
  expansion can rely on it. `'nothing` gives the `nothing` value rather than a
  symbol, a host's `define` rejects the name with `invalidName`, and
  `MyronSession.query("nothing")` no longer finds a binding.
- A parameter list cannot name the same parameter twice, including a variadic
  parameter once its `...` is removed, as in `(xs xs...)`. Procedures and macros
  both reject one with the new `duplicateName` and a hint. Before, the later
  parameter silently won.
- `unexpectedType` messages quote the kinds they name, as in `Unexpected type,
  got 'string', expected 'integer'`. A host that matches on the message text
  will need updating; the `Reason` itself is unchanged.
- `invalidName` is also raised for a record type or field name that Myron
  source could not write, and for a module or export name that has a dot in it
  or is a special form's name, and so can now come back from `eval`.
- `MyronSession.set(_:to:)` throws, and rejects with `invalidName` any name that
  a host's `define` would reject. Before, it bound any string, so a host could
  bind a name such as `"if"`, `"nothing"` or `"two words"` that no program
  could reach. A call to `set` now needs `try`.
- A name being bound cannot contain a `"`. Before, `(define a"b" 1)` was
  accepted, since the lexer reads `a"b"` as one symbol.
- `MyronSession.query` resolves a dotted name that is not bound as it stands
  as a qualified name, so it can now find a module's export.
- No name can end in a dot, since a trailing `...` marks a variadic parameter.
  `define`, `let`, procedure parameters, modules and their exports, record types
  and fields, and a host's `define` all reject one with `invalidName`. Before,
  `(define x. 1)` was accepted. A variadic parameter that still ends in a dot
  once its `...` is removed, such as `x....`, is rejected the same way.

### Fixed

- The executable builds for Wasm again. The REPL banner asked the terminal for
  its width in a way WASI does not support, so since `0.2.0` only the library
  could be built there. On WASI, the banner now takes its width from `COLUMNS`,
  or uses 80 columns.

## [0.2.0] — 2026-09-23

Three new data types, a two-way bridge to Swift, and primitives written in
Swift. The public Swift interface has been renamed throughout, so hosts written
against `0.1.0` will need updating — see [Changed](#changed-1) and
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

[Unreleased]: https://github.com/ncke/myron/compare/0.3.0...HEAD
[0.3.0]: https://github.com/ncke/myron/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/ncke/myron/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/ncke/myron/releases/tag/0.1.0
