<p align="center">
  <img src="docs/banner.svg" alt="Myron — eval, apply, repeat" width="720">
</p>

# Myron

Myron is a small Lisp implemented in Swift, designed to be embedded in a Swift
application. It is a single package with no dependencies: add it, create a
session, and evaluate source.

```lisp
(define (factorial n)
  (if (== n 0)
      1
      (* n (factorial (- n 1)))))

(factorial 10)                            ; 3628800

(define (square x) (* x x))
(map square '(1 2 3 4))                   ; (1 4 9 16)

(reduce + 0 (filter (lambda (x) (> x 2)) '(1 2 3 4 5)))
                                          ; 12
```

If you write Swift but have never written a Lisp, the rest of this page is
meant to be read top to bottom: the [Swift interface](#the-swift-interface)
shows how to host the interpreter, [a tour of Myron](#a-tour-of-myron) teaches
the language from scratch, and the two reference sections at the end are for
looking things up later.

## Contents

- [Features](#features)
- [Getting started](#getting-started)
- [The Swift interface](#the-swift-interface)
  — [`MyronSession`](#myronsession) · [`MyronResult`](#myronresult) ·
  [`MyronValue`](#myronvalue) · [`MyronError`](#myronerror) ·
  [Swift interoperability](#swift-interoperability) ·
  [Configuration](#configuration) ·
  [Lifetime and threading](#lifetime-and-threading)
- [A tour of Myron](#a-tour-of-myron)
- [Language reference](#language-reference)
  — [Lexical structure](#lexical-structure) ·
  [Evaluation model](#evaluation-model) · [Special forms](#special-forms)
- [Standard library reference](#standard-library-reference)
  — [Comparison](#comparison) · [Predicates](#predicates) ·
  [Logic](#logic) · [Mathematics](#mathematics) · [Sequences](#sequences) ·
  [Lists](#lists) · [Association lists](#association-lists) ·
  [Hashmaps](#hashmaps) · [Sets](#sets) ·
  [Strings](#strings) · [Higher-order functions](#higher-order-functions)
- [Status](#status)
- [Licence](#licence)

## Features

- Classic s-expression syntax, with `quote` and its `'` abbreviation.
- Nine special forms: `and`, `begin`, `cond`, `define`, `if`, `lambda`, `let`,
  `or`, and `quote`.
- Lexically scoped closures. `and` and `or` short-circuit.
- Proper tail calls. A tail-recursive loop runs in constant stack, and the
  interpreter's continuation stack lives on the heap, so recursion depth is
  bounded by a configurable limit rather than by the host's thread stack.
- A standard environment covering comparison, predicates, logic, mathematics,
  sequences, lists, association lists, hashmaps, sets, strings, and the
  higher-order staples (`map`, `filter`, `reduce`, `all`, `any`).
- Two associative types behind one set of names: `get`, `put` and friends
  resolve over alists and hashmaps alike.
- Swift interoperability in both directions. Swift values convert to
  `MyronValue`, which reads back through typed accessors, converts into Swift
  types on request, and is expressible as a Swift literal. A host's own types
  join in by conforming to the same two protocols the built-in ones use.
- `MyronValue` is `Hashable`, so Myron values can be held in Swift's own sets
  and dictionaries, and compared without going back through the interpreter.
- Any value can be a hashmap or alist key, or a member of a set — a list, a
  nested hashmap, even a procedure — with no separate key type to convert
  through.
- A set type with the usual algebra: `union`, `intersection`, `difference`,
  `symmetric-difference`, the subset and superset relations, and `is-disjoint?`.
  Sets compare by membership, so `(eq (set 1 2) (set 2 1))` is `true`.
- `map` and `filter` give back the kind they were given, so a set maps to a set
  and a list to a list.
- A session's environment is open to its host: names can be read, written and
  listed from Swift without going through source text.
- Primitives can be written in Swift and called from Myron. A host supplies a
  closure of up to six arguments and gets arity checking, namespacing and error
  reporting for free — a failure inside the closure arrives as an ordinary
  Myron diagnostic, complete with a source location and caret.
- Sequence primitives that work on both lists and strings, resolved on the
  types of the arguments: `(length '(1 2 3))` and `(length "abc")` are both `3`.
- Strict, coercion-free numerics: integers and doubles never mix silently.
- Errors are values, not traps. Overflow, division by zero, runaway recursion
  and type mismatches all come back as a `MyronError` rather than crashing the
  host process.
- Diagnostics carry a source location and render with a caret highlight.
- No dependencies.

## Getting started

Myron is a Swift package built with the Swift 6.3 toolchain in Swift 6 language
mode. Clone it and check that everything works:

```bash
swift build
swift test
```

Take the language for a spin in the REPL:

```bash
swift run myron-repl
```

```
.        ·        .       ·      .       ·      .      ·      .      ·       .
    ·       *        .       ·      +       .      ·     .      ·      .

   ████ ·████  ▀██▄ ▄██▀  █████████  █████████  ███▄   ██   *      *      *
*  ██ ████ ██    ▀███▀    ██  ·  ██  ██     ██  ██▀█▄ ·██    **     **  .  **
   ██  ██  ██     ██      █████████  ██  ·  ██  ██  ▀█▄██     **  .  **     **
 · ██      ██     ██      ██ · ████  █████████  ██   ▀███    **     **     **
.    ·     .        *      .      ·         version 0.1.1   *   .  *      *
         ·       .       ·      .     *      .      ·          ·      .      ·

Ready.
> (+ 1 2)
3
> (map (lambda (x) (* x x)) '(1 2 3))
(1 4 9)
```

The banner is drawn in colour when the terminal supports it, and in plain text
when it does not — it is dropped if `NO_COLOR` is set, if `TERM` is unset or
`dumb`, or if output is redirected to a file or a pipe.

The REPL reads one line at a time, so keep each entry on a single line.
Definitions persist for the life of the process.

To use Myron in your own project, add it to your package dependencies and
depend on the `Myron` library product:

```swift
dependencies: [
    .package(url: "https://github.com/ncke/myron.git", from: "0.1.1")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [.product(name: "Myron", package: "myron")]
    )
]
```

## The Swift interface

Myron is a library first. The public surface is deliberately small: a session,
its configuration, a result, the `MyronValue` enum, `MyronHashmap`,
`MyronSet`, `MyronError`, and the language version. The `myron-repl`
executable is itself just another host of the library, in a few dozen lines of
Swift.

```swift
import Myron

let session = MyronSession()
let result = session.eval("(+ 1 2)")      // .success(.integer(3))

print(MyronLanguage.version)              // 0.1.1
```

### `MyronSession`

A session owns a top-level environment and an evaluator. Definitions persist
across calls, so successive `eval` calls behave like entries at a REPL:

```swift
let session = MyronSession()

_ = session.eval("(define (square x) (* x x))")
let result = session.eval("(square 7)")   // .success(.integer(49))
```

`eval` has one required parameter and one optional one:

```swift
public func eval(_ expression: String, sourceHandle: Int? = nil) -> MyronResult
```

A single call may contain any number of top-level forms. They are evaluated in
order, the value of the last form is returned, and the first error stops
evaluation:

```swift
let result = session.eval("""
    (define (double x) (* x 2))
    (define xs '(1 2 3))
    (map double xs)
    """)

// result is .success(.list([.integer(2), .integer(4), .integer(6)]))
```

`sourceHandle` tags input with its origin — a file identifier, a REPL entry
number — and is carried through tokenisation. It is not yet surfaced on
errors, so treat it as reserved.

Each session is independent. Create a new one when you want a clean
environment; there is no way to reset an existing one.

#### Reading and writing the environment

A session's top-level environment is open to the host. `query` resolves a name
the way Myron would, `set` binds one, and `names` lists what is bound:

```swift
session.set("limit", to: 10)
session.eval("(< 3 limit)")               // .success(.boolean(true))

session.query("limit")                    // .integer(10)
session.query("pi")                       // .double(3.14159...) — standard
session.query("nowhere")                  // nil

session.names                             // Set<String>
```

`set` takes a `MyronValue`, so data a host has built — a number, a string, a
list, a hashmap — can be handed to Myron without going through source text. It
never fails, and it overwrites whatever was there before, whether the host or a
`define` put it there. Myron's own `define` overwrites it in turn: the two
write to the same place.

`query` resolves a name exactly as evaluation would, so it reaches the
[standard environment](#standard-library-reference) as well as what has been
bound in the session. A `nil` result means the name is unbound, which is
distinct from a name bound to `nothing`:

```swift
session.set("n", to: nil)                 // bound to nothing
session.query("n")                        // .some(.nothing)
session.query("m")                        // nil — never bound
```

`names` reports only what has been bound in the session, by `define` or by
`set`. It does not list the standard environment or the special forms, so a
name can be resolvable through `query` without appearing in `names`. Local
bindings from `let` and from procedure calls do not appear either; they belong
to inner environments that do not outlive the call.

Nothing stops a host from shadowing a standard name — `set("map", to: 9)` makes
`map` an integer for that session, exactly as `(define map 9)` would. It is the
host's session to furnish.

#### Defining primitives

`set` hands Myron a value. `define` hands it a function: a Swift closure that
Myron can call like any other primitive.

```swift
let session = MyronSession()

try session.define("double") { value in
    try value.requireInteger() * 2
}

session.eval("(double 21)")               // .success(.integer(42))
session.eval("(map double '(1 2 3))")     // .success — the list (2 4 6)
```

There is an overload for each arity from zero to six. The closure's shape
chooses the overload, so nothing needs declaring:

```swift
try session.define("answer") { 42 }

try session.define("hypotenuse") { a, b in
    let x = try a.requireDouble()
    let y = try b.requireDouble()
    return (x * x + y * y).squareRoot()
}

session.eval("(hypotenuse 3.0 4.0)")      // .success(.double(5.0))
```

A body returns anything [representable](#swift-interoperability) — a Swift
scalar, an array, a dictionary, a set, a `MyronValue`, or one of the host's own
types — and takes its arguments as `MyronValue`, already evaluated, to read with
the [conversions](#converting-into-swift-types) below.

Arity is checked before the body runs, so a body never sees the wrong number of
arguments:

```swift
session.eval("(double 1 2)")
// .failure — Unexpected arity: got 2, expected 1
```

A primitive defined this way is an ordinary value in the session's environment.
It can be shadowed by a later `define`, replaced by Myron's own `define`, passed
to `map` and friends, stored in a list or a hashmap and called back out, and
read through `query`. It is namespaced under `host.` so it is recognisable on
sight:

```swift
session.eval("double")                    // <primitive: host.double>
```

**Failing from a body.** Throw `MyronHostError` and its description arrives as
the reason, positioned at the call site:

```swift
try session.define("checked") { value in
    let n = try value.requireInteger()
    guard n > 0 else { throw MyronHostError("expected a positive number") }
    return n
}

session.eval("(checked -1)")
// .failure — Host error: expected a positive number
```

Any other Swift error works too and is described by `String(describing:)`, so an
error that implements `CustomStringConvertible` reports its own text. A
`MyronError` thrown from a body — which is what the conversions below throw —
passes through unchanged except that it gains the call site if it had no
location, so a type mismatch inside a body reads exactly like one raised by the
standard library:

```swift
session.eval("(double \"a\")")
// ERROR: Unexpected type, got string, expected integer
// (double "a")
// ^^^^^^^^^^^^
```

**Naming.** `define` throws rather than returning, because a name has to be one
Myron source could actually write. Validation runs the lexer itself: the name
must lex as exactly one symbol token equal to the name given. That rules out the
empty string, anything containing whitespace, brackets, a `;`, a `'` or a `"`,
and anything that would lex as something else — `42`, `3.5`, `true`. The nine
[special forms](#special-forms) are rejected too, since they are intercepted
before symbol lookup and a primitive under one of those names could never be
called. Everything else is fair game, including non-ASCII: if `(define café 1)`
works in source, `define("café")` works from Swift.

```swift
try session.define("if") { _ in 1 }       // throws — Invalid name: if
try session.define("two words") { _ in 1 }// throws — Invalid name: two words
try session.define("café") { _ in 1 }     // fine
```

**Capturing.** A body must not capture its own session. The session owns the
environment that holds the closure, so capturing it would form a cycle the
session could never break. The signature is `@Sendable`, which turns that
mistake into a compile error rather than a leak:

```swift
try session.define("wrong") { _ in session.names.count }
// error: capture of 'session' with non-Sendable type 'MyronSession'
//        in a '@Sendable' closure
```

Read what a body needs before defining it, or hold the state in a `Sendable`
type of your own.

### `MyronResult`

`eval` returns a `MyronResult`, a three-case enum:

```swift
public enum MyronResult {
    case success(MyronValue)
    case failure([MyronError])
    case nothing
}
```

```swift
switch session.eval(source) {

case .success(let value):
    print(value)                          // MyronValue is CustomStringConvertible

case .failure(let errors):
    for error in errors {
        print(error.message ?? error.reason.description)
    }

case .nothing:
    break                                 // the source contained no forms
}
```

`.nothing` is returned only when the input holds no forms at all — it was
empty, whitespace, or nothing but comments. It is distinct from a successful
evaluation that produced the Myron value `nothing`, which arrives as
`.success(.nothing)`.

A `failure` carries an array because lexing and parsing report every problem
they find in one pass. Evaluation, by contrast, stops at the first error, so an
evaluation failure always holds exactly one.

Each case has a test and, where there is something to extract, an accessor:

```swift
let result = session.eval(source)

result.isSuccess                          // Bool
result.asSuccess                          // MyronValue?
result.isFailure                          // Bool
result.asFailure                          // [MyronError]?
result.isNothing                          // Bool
```

### `MyronValue`

`MyronValue` is an enum covering every kind of Myron value:

```swift
public enum MyronValue {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case string(String)
    case symbol(String)
    case list([MyronValue])
    case hashmap(MyronHashmap)
    case set(MyronSet)
    case nothing
    case procedure(MyronProcedure)        // a lambda or a defined procedure
    case primitive(MyronPrimitive)        // a built-in function
    case higherOrder(MyronHigherOrder)    // map, filter, reduce
    case higherProbe(MyronHigherProbe)    // all, any
    case define(String)                   // the marker a definition returns
}
```

Extract Swift values by pattern matching:

```swift
if case .integer(let n) = value {
    print(n + 1)
}

if case .list(let elements) = value {
    print(elements.count)
}
```

Or through the typed accessors, each of which is `nil` for any other case:

```swift
value.asBoolean                           // Bool?
value.asInteger                           // Int?
value.asDouble                            // Double?
value.asString                            // String?
value.asSymbol                            // String?
value.asList                              // [MyronValue]?
value.asHashmap                           // MyronHashmap?
value.asSet                               // MyronSet?
```

These do not coerce: `MyronValue.integer(1).asDouble` is `nil`, exactly as
`(== 1 1.0)` is `false` in Myron. `.procedure`, `.primitive` and `.define` have
no accessor — match on them if you need them.

`MyronValue` conforms to `CustomStringConvertible`, and its `description`
renders a value the way Myron prints it: lists in brackets, strings in quotes,
and the absence of a value as `<nothing>`. A procedure renders as `<procedure>`,
and a primitive names itself, qualified by the standard library module that
registered it:

```
+       <primitive: mathematics.add>
map     <primitive: higher.map>
head    <primitive: *.head>       — `*` for a name several modules answer
```

Every value also reports a `MyronValue.Kind` — a plain, `Equatable` enum with no
associated values — which is what error messages talk about and what you want
when you only care about the type:

```swift
guard value.kind == .list else { return nil }        // not a list
```

`MyronValue` is `Equatable` and `Hashable`, so values can be compared directly
and held in Swift's own `Set` and `Dictionary`:

```swift
let seen: Set<MyronValue> = [.integer(1), .string("a")]
seen.contains(.integer(1))                // true
```

Equality is structural and does not coerce, matching Myron's own `eq`: lists
compare element by element, hashmaps by their contents and sets by their
membership, both regardless of the order they were built in, and an integer
never equals a double.

Every case answers, including the callable ones. A `.primitive` compares by the
name it registered under, so `+` equals `+`. A `.procedure` compares by
identity, so a procedure equals itself but not a separately written twin:

```swift
session.eval("(define (f x) x)")
session.eval("(eq f f)")                  // true
session.eval("(eq (lambda (x) x) (lambda (x) x))")   // false
```

The one value that does not equal itself is `nan`, which follows the IEEE rule
Swift already applies — `(eq (sqrt -1.0) (sqrt -1.0))` is `false`.

### `MyronError`

```swift
public struct MyronError: Error, Sendable {
    public let reason: Reason             // what went wrong
    public let location: MyronLocation?   // where, a Range<Int> of offsets
    public let message: String?           // a pre-rendered diagnostic
}
```

`location` is a `Range<Int>` of character offsets into the string you passed to
`eval`, which is enough to underline the offending text in an editor. `message`
is populated in the default verbose [error style](#configuration) and renders
the source line with a caret highlight:

```
ERROR: Unrecognised symbol
(+ 1 undefined)
     ^^^^^^^^^
```

`reason` is an enum you can switch over to react programmatically. Every case
also has a `description`, which is the first line of the rendered message.

| Reason | Raised when |
|---|---|
| `ambiguousResolution(String, String, [String])` | Two standard primitives matched a call equally well; carries the name, the argument kinds, and the primitives that tied. |
| `cannotBeNegative` | A count that must be non-negative was not — `(take -1 xs)`. |
| `containingEnvironmentNoLongerExists` | A procedure was called after the session that defined it was deallocated. |
| `couldNotResolve(String, String, [String])` | No standard primitive of that name accepts that shape of call; carries the name, the argument kinds, and the forms that would have worked. |
| `divisionByZero` | `/`, `mod`, or `rem` was given a zero divisor. |
| `duplicateKeys([Int])` | A key was found more than once in an alist; carries the indices. |
| `emptyApplication` | The form `()` was evaluated. |
| `exceededMaximumStackDepth(Int)` | Recursion passed the configured limit; carries the depth reached. |
| `expectedExpressionAfterTick` | A `'` was not followed by an expression. |
| `expectedFunction(MyronValue.Kind)` | The head of an application was not callable. |
| `expectedQuote` | A string literal was never closed. |
| `hostError(String)` | A [host-defined primitive](#defining-primitives) threw; carries the error's description. |
| `incomparableTypes` | `gt`/`lt` and friends were given types with no ordering. |
| `` `internal`(String) `` | An invariant inside the interpreter broke. Please report these. |
| `invalidName(String)` | `define` was given a name Myron source could not write; carries the name. Thrown by `define` itself, never by `eval`. |
| `invalidNumber` | A numeric token or cast could not be read as a number. |
| `malformedAlist(Int)` | An alist entry was not a two-element list; carries the index. |
| `overflow` | Integer arithmetic exceeded `Int`. |
| `subscriptOutOfBounds(Int, Int)` | An `nth` index fell outside the sequence; carries index and length. |
| `typeCastFailed(MyronValue.Kind, MyronValue.Kind)` | `integer` or `double` was applied to a value it cannot convert. |
| `unexpectedArity(Int, IntegerExpectation)` | Wrong number of arguments; carries what was given and what was wanted. |
| `unexpectedType(MyronValue.Kind?, Set<MyronValue.Kind>)` | Wrong type of argument; carries what was given and what was acceptable. |
| `unimplementedFeature` | Reserved for primitives that are declared but not yet implemented. Nothing raises it today. |
| `unmatchedParenthesis` | A bracket had no partner — a `(` that was never closed, or a `)` with nothing to close. The location points at the unmatched bracket. |
| `unrecognisedSymbol` | A symbol had no binding. |

### Swift interoperability

Values cross the boundary in both directions, and each direction has a protocol:
`MyronValueRepresentable` goes out to Myron, `MyronValueConvertible` comes back
into Swift. The built-in types conform to both, and a host's own types can join
them.

`MyronValueRepresentable` turns a Swift value into a `MyronValue`:

```swift
7.myronValue                              // .integer(7)
"a".myronValue                            // .string("a")
[1, 2, 3].myronValue                      // .list([...])
["a": 1].myronValue                       // .hashmap(...)
Optional<Int>.none.myronValue             // .nothing
```

`Bool`, `Double`, `Int`, `String`, `Array`, `Dictionary` and `Optional` conform,
as does `MyronValue` itself, so a value you already hold can be used wherever a
representable one is wanted. There is no separate key type: a hashmap is keyed
by `MyronValue`, so anything that can be a value can be a key.

`MyronValue` is expressible as a Swift literal, which is usually the shortest
way to build one:

```swift
let a: MyronValue = 42
let b: MyronValue = "text"
let c: MyronValue = nil                   // .nothing
let d: MyronValue = [1, "two", true]      // a list of mixed types
let e: MyronValue = ["a": 1, "b": true]   // a hashmap of mixed types
```

An array literal becomes a list and a dictionary literal becomes a hashmap.
Both take anything representable, so variables sit alongside literals and
collections nest:

```swift
let count = 3
let config: MyronValue = [
    "retries": count,                     // a variable
    "tags": ["a", "b"],                   // a nested list
    "limits": ["max": 10]                 // a nested hashmap
]
```

Keys are values like any other, so a key can be a list, a hashmap, or a
`MyronValue` you already hold:

```swift
let hashmap: MyronHashmap = [
    "a": 1,                               // a Swift literal
    MyronValue.double(1.5): 2,            // a Myron value
    [1, 2]: 3                             // a list as a key
]
```

#### Converting into Swift types

The [accessors](#myronvalue) return an optional and say nothing about why they
failed. `MyronValueConvertible` is the other way round: it throws, with the same
diagnostics the standard library raises. There are named accessors for the
scalars, which need no annotation:

```swift
try value.requireBoolean()                // Bool
try value.requireInteger()                // Int
try value.requireDouble()                 // Double
try value.requireString()                 // String
try value.requireSymbol()                 // String, from a symbol
```

And a generic `require()` for everything else, which takes its type from
context:

```swift
let count: Int = try value.require()
let names: [String] = try value.require()
let limits: [String: Int] = try value.require()
let nested: [String: [Int]] = try value.require()
let unique: Set<Int> = try value.require()
let held: MyronValue = try value.require()
```

Nesting comes free, so a structure converts in one step however deep it goes.
`Array`, `Set`, `Dictionary` and `Optional` conform where their elements do;
`MyronValue`, `MyronHashmap` and `MyronSet` conform as themselves. A list and a
set each convert into either Swift collection, so the Swift type you ask for
decides the shape — and asking for a `Set` collapses duplicates, as Swift's `Set`
always does. `nothing` becomes `nil` for an optional and an error for anything
else.

`require()` is the one to reach for when context already fixes the type, which
is what makes it read well in argument position:

```swift
struct Config { var retries: Int; var name: String }

let config = try Config(retries: a.require(), name: b.require())
```

Where no type is fixed, use a named accessor instead — it is shorter, because it
needs no annotation. Symbols only have the named accessor: `.string` and
`.symbol` are two Myron kinds for one Swift type, and the generic conversion
takes the string.

A failure reports what was found and what was wanted, and names the innermost
type rather than the outermost:

```swift
let _: Int = try MyronValue.string("a").require()
// Unexpected type, got string, expected integer

let _: [Int] = try MyronValue.list([.integer(1), .string("x")]).require()
// Unexpected type, got string, expected integer — the element, not the list
```

Conversions throw without a location, because on their own there is no source to
point at. Inside a [host primitive](#defining-primitives) the call site is added
on the way out, which is what makes a conversion failure in a body read like any
other diagnostic.

**A host's own types.** Conform to both protocols and a type crosses the
boundary like a built-in one, nesting included:

```swift
struct Version: Equatable {
    var major: Int
    var minor: Int
}

extension Version: MyronValueConvertible {
    init(myronValue: MyronValue) throws {
        let parts: [Int] = try myronValue.require()
        guard parts.count == 2 else {
            throw MyronHostError("a version needs two parts")
        }
        self.init(major: parts[0], minor: parts[1])
    }
}

extension Version: MyronValueRepresentable {
    var myronValue: MyronValue { [major, minor].myronValue }
}
```

```swift
let one: MyronValue = [1, 2]
let many: MyronValue = [[1, 0], [2, 1]]

let version: Version = try one.require()
let versions: [Version] = try many.require()   // nests, with no extra work

try session.define("bump") { value in
    let version: Version = try value.require()
    return Version(major: version.major, minor: version.minor + 1)
}

session.eval("(bump '(1 2))")             // .success — the list (1 3)
```

#### `MyronHashmap`

The payload of `MyronValue.hashmap`. It is an immutable value type with a
dictionary-shaped Swift interface:

```swift
hashmap.count                             // Int
hashmap.isEmpty                           // Bool
hashmap["a"]                              // MyronValue?
hashmap.keys                              // [MyronValue]
hashmap.values                            // [MyronValue]
hashmap.pairs                             // [(key: MyronValue, value: …)]
hashmap.dictionary                        // [MyronValue: MyronValue]
```

It conforms to `Sequence`, so it iterates and composes like any other
collection:

```swift
for (key, value) in hashmap {
    print(key, value)
}

let names = hashmap.keys.map(\.description)
```

Build one from a Swift dictionary, or from Myron types directly:

```swift
let a = MyronHashmap(["a": 1, "b": 2])
let b = MyronHashmap([MyronValue.string("a"): MyronValue.integer(1)])
```

Neither initialiser throws. An entry whose value is absent — a Swift `nil`, or
`.nothing` written explicitly — is dropped rather than stored, which is the same
rule `put` follows in Myron. An entry whose key holds a `nan` is dropped too;
see [keys](#keys) below.

A dictionary literal is the shortest form, and takes variables as readily as
literals:

```swift
let key = "k"
let absent: Int? = nil

let hashmap: MyronHashmap = [
    "a": 1,                               // Swift literals
    "b": [1, 2],                          // nested collections
    key: "value",                         // variables
    "c": absent                           // dropped
]
```

One rule applies to literals that would otherwise be silent: a duplicated key
keeps the first entry and discards the rest.

A `MyronValue` dictionary literal builds a hashmap through the same code, so
everything here applies to it too.

Note that iteration order is unspecified, so `keys`, `values`, `pairs` and
`description` may come back in a different order on each run.

#### `MyronSet`

The payload of `MyronValue.set`. Like `MyronHashmap` it is an immutable value
type, and every operation returns a new set rather than modifying the receiver:

```swift
set.count                                 // Int
set.isEmpty                               // Bool
set.contains(.integer(1))                 // Bool
set.insert(.integer(4))                   // MyronSet
set.remove(.integer(1))                   // MyronSet
```

The algebra and the relations are there under their Swift names:

```swift
a.union(b)                                // MyronSet
a.intersection(b)                         // MyronSet
a.difference(b)                           // MyronSet — a without b's members
a.symmetricDifference(b)                  // MyronSet

a.isSubset(of: b)                         // Bool
a.isStrictSubset(of: b)                   // Bool
a.isSuperset(of: b)                       // Bool
a.isStrictSuperset(of: b)                 // Bool
a.isDisjoint(with: b)                     // Bool
```

It conforms to `Sequence`, so it iterates and composes like any other
collection, and an array literal is the shortest way to build one:

```swift
let a: MyronSet = [1, "two", true]        // mixed types, as in Myron
let b = MyronSet(Set([1, 2, 3]))          // from a Swift Set
let c = MyronSet([MyronValue.string("a")])

for member in a { print(member) }
let rendered = a.map(\.description)
```

The array literal takes anything representable, so variables and nested
collections sit alongside literals. Note that it builds a *set*, not a list —
a `MyronValue` array literal still builds a list, so reach for `.set(…)` when
you want a set value:

```swift
let asList: MyronValue = [1, 2, 2]        // .list — three elements
let asSet = MyronValue.set([1, 2, 2])     // .set — two members
```

Like a hashmap key, a member holding a `nan` is dropped rather than stored; see
[keys](#keys) below. Iteration order is unspecified, so `description` and any
traversal may come back in a different order on each run.

`MyronSet` is `Equatable` and `Hashable`, comparing by membership, which means
a set can itself be a member of a set, a hashmap key, or an element of Swift's
own `Set`:

```swift
MyronSet([1, 2]) == MyronSet([2, 1])      // true
```

#### Keys

A hashmap is keyed by `MyronValue`, so any value is a key — a string, a list, a
nested hashmap, even a procedure. Keys are compared structurally and never
coerce, so `1`, `1.0` and `"1"` are three different keys.

The one exception is a `nan`, which is not equal to itself. An entry stored
under one could never be found again, so a key holding a `nan` anywhere inside
it is dropped rather than stored — silently, on every path that builds a
hashmap, in Swift and in Myron alike:

```swift
let hashmap: MyronHashmap = [Double.nan: 1, [1, Double.nan]: 2, "a": 3]
hashmap.count                             // 1 — only "a" survives
```

The same rule applies to set members, for the same reason — a member that is
not equal to itself could never be found — so a `nan` is dropped on every path
that builds a set too:

```swift
let set: MyronSet = [Double.nan, 1]
set.count                                 // 1 — only 1 survives
```

This applies to keys and members only. A `nan` is a perfectly good *value*, and
a list is free to hold one. Infinities are unaffected in every position: an
infinity equals itself, so it keys, stores and finds like anything else.

### Configuration

```swift
let session = MyronSession(
    configuration: MyronSessionConfiguration(
        errorStyle: .terse,
        maximumStackDepth: 10_000))
```

| Setting | Values | Default (`.standard`) |
|---|---|---|
| `errorStyle` | `.verbose` renders `message`; `.terse` leaves it `nil` | `.verbose` |
| `maximumStackDepth` | An `Int` limit, or `nil` for no limit | `2000` |

Choose `.terse` when you are going to format diagnostics yourself from `reason`
and `location` — it skips rendering work you would only throw away.

`maximumStackDepth` bounds the interpreter's continuation stack. Because that
stack lives on the heap, exceeding the limit is a clean
`exceededMaximumStackDepth` failure rather than a crash, and the session stays
usable afterwards. Tail calls do not consume depth at all, so the limit only
constrains genuinely non-tail recursion — `2000` is generous for most
programs, and raising it costs memory rather than safety. Setting it to `nil`
removes the check entirely; only do that for source you trust.

### Lifetime and threading

Sessions are not thread-safe. Confine each one to a single thread or actor.

When a session is deallocated it shuts down every environment it created. This
matters because closures capture their defining environment, and a procedure
stored in an environment forms a reference cycle with it; the session's
registry breaks those cycles at teardown. The practical consequence is that a
`.procedure` value is only meaningful while the session that produced it is
alive — extract the data you need before letting the session go.

Calling one afterwards is an error rather than a crash: the procedure has no
environment left to run in, and evaluation fails with
`containingEnvironmentNoLongerExists`. That applies however the procedure is
reached, including from inside a list or hashmap it was stored in.

The same reasoning applies to a [host primitive](#defining-primitives) from the
other side. A session owns the environment that holds the closure, so a body that
captured its session would form a cycle nothing could break, and the registry
would never get to run. The `@Sendable` signature makes that a compile error, and
it also means anything a body does capture has to be `Sendable` — which is worth
knowing before you reach for a non-`Sendable` service inside one.

## A tour of Myron

This section assumes you know Swift and are new to Lisp. Everything here can be
typed straight into `swift run myron-repl`.

### Everything is an expression

A Myron program is a sequence of *s-expressions*. An s-expression is either an
**atom** — a number, a boolean, a string, or a symbol — or a **list** of
s-expressions in brackets. Evaluating an expression produces a value; there are
no statements.

A list is evaluated as a function application. The first element is the
function and the rest are its arguments, so what Swift writes as `f(a, b)`
Myron writes as `(f a b)`:

```lisp
(+ 1 2)                                   ; 3
(max 3 1 4 1 5)                           ; 5
(+ 1 (* 2 3))                             ; 7
```

Arithmetic looks unusual at first because the operator moves to the front, but
it buys uniformity: `+` is an ordinary function like any other, and it takes as
many arguments as you care to give it.

Comments run from a `;` to the end of the line.

```lisp
(+ 1 2)   ; three
```

### Values and types

Myron has integers, doubles, booleans, strings, symbols, lists, hashmaps, sets,
and `nothing`.

```lisp
42                                        ; integer
3.14                                      ; double
true                                      ; boolean
"hello"                                   ; string
'x                                        ; symbol
'(1 2 3)                                  ; list
(set 1 2 3)                               ; set
```

Only the first six can be written as literals. A hashmap is built with
`make-hashmap` and a set with `set` or `make-set`.

Numbers are strict about their types. An integer is an `Int` and a double is a
`Double`, and Myron will never quietly promote one to the other:

```lisp
(+ 1 2.0)                                 ; ERROR: Unexpected type, got double,
                                          ; expected integer
(+ 1 (integer 2.0))                       ; 3
(+ (double 1) 2.0)                        ; 3.0
```

This is the same discipline Swift applies to `Int` and `Double`, for the same
reason: silent coercion hides the moment precision is lost. Convert explicitly
with `integer` and `double`.

Strings are double-quoted. There are no escape sequences yet, so a string
cannot contain a `"` character. A literal may run across several lines of
source, with the newlines becoming part of the string — though not at the
line-based REPL.

`nothing` is the absence of a value. It is what `head` gives you for an empty
list, and it is bound to the name `nothing` so you can write one down. It is
equal to itself and to nothing else, so `nothing?` and `eq` both work on it.

```lisp
(head '())                                ; <nothing>
(nothing? (head '()))                     ; true
(eq nothing (head '()))                   ; true
(eq nothing 0)                            ; false
```

### Naming things with `define`

```lisp
(define greeting "hello")
greeting                                  ; "hello"
```

`define` also has a shorthand for procedures. These two are the same:

```lisp
(define square (lambda (x) (* x x)))
(define (square x) (* x x))

(square 7)                                ; 49
```

A `define` does not return the value it bound — it returns a marker that the
REPL prints as `<define: square>`. Bind first, use afterwards.

### Branching with `if` and `cond`

`if` takes exactly three arguments: a condition, a consequent, and an
alternative. It evaluates the condition and then only the branch it selects.

```lisp
(define (classify n)
  (if (< n 0) "negative" "non-negative"))

(classify -3)                             ; "negative"
```

The condition must be a boolean. Myron has no notion of truthiness, so
`(if 1 "a" "b")` is a type error rather than a surprise. Both branches are
required — `if` is an expression and has to produce a value either way.

For a chain of tests, `cond` is easier to read than nested `if`s. It takes a
series of clauses, each a list whose first element is a test:

```lisp
(define (fizzbuzz n)
  (cond ((== 0 (mod n 15)) "fizzbuzz")
        ((== 0 (mod n 3))  "fizz")
        ((== 0 (mod n 5))  "buzz")
        (true              (string n))))

(map fizzbuzz '(1 3 5 15))                ; ("1" "fizz" "buzz" "fizzbuzz")
```

The clauses are tried in order and the first matching one wins. There is no
`else` keyword; a final clause whose test is `true` plays that role. If nothing
matches, `cond` yields `nothing`.

`and` and `or` short-circuit, which makes them useful as guards:

```lisp
(define (safe-head? xs)
  (and (not (empty? xs)) (> (head xs) 0)))

(safe-head? '())                          ; false — head is never reached
```

### Procedures and closures

`lambda` builds an anonymous procedure. It takes a parameter list and one or
more body expressions, and yields the value of the last one:

```lisp
((lambda (x y) (+ x y)) 3 4)              ; 7
```

Procedures are lexically scoped closures: they capture the environment in which
they were created, not the one in which they are called. That is what makes
this work:

```lisp
(define (adder n)
  (lambda (x) (+ x n)))

(define add5 (adder 5))
(add5 3)                                  ; 8
```

`add5` still has its own `n` long after `adder` returned. If you have written
`{ x in x + n }` in Swift, this is the same idea with the same rules.

Procedure arity is exact. Calling `add5` with two arguments is an error, and
there is no automatic currying — `(adder 5)` returns a procedure because you
wrote a `lambda`, not because of anything the language did on your behalf.

### Local bindings with `let` and `begin`

`let` introduces names for the extent of its body:

```lisp
(let ((radius 3.0)
      (area (* pi (* radius radius))))
  area)                                   ; 28.274333882308138
```

Bindings are sequential, so `area` can see `radius`. The names disappear when
the `let` ends, and they shadow rather than overwrite anything outside.

`begin` evaluates several expressions in order and yields the last, which is
useful wherever the grammar wants exactly one expression:

```lisp
(define (describe n)
  (if (> n 0)
      (begin (define doubled (* n 2)) (list n doubled))
      '()))

(describe 4)                              ; (4 8)
```

Unlike `let`, `begin` does not create a scope — a `define` inside one lands in
the surrounding environment.

### Lists and quoting

Lists are Myron's one compound data structure, and they are also its syntax.
That means a literal list needs protecting from evaluation, which is what
`quote` does:

```lisp
(+ 1 2)                                   ; 3 — evaluated as an application
'(+ 1 2)                                  ; (+ 1 2) — kept as data
```

`'expr` is shorthand for `(quote expr)`, and it protects the whole expression,
recursively. `'()` is the empty list, and `'x` is a symbol — the only way to
get one.

Build lists with `list` and `cons`, take them apart with `head` and `tail`:

```lisp
(list 1 2 3)                              ; (1 2 3) — arguments are evaluated
(cons 1 '(2 3))                           ; (1 2 3)
(append '(1) '(2 3))                      ; (1 2 3)
(head '(1 2 3))                           ; 1
(tail '(1 2 3))                           ; (2 3)
```

Those last two are the shape of most list recursion. A list is either empty or
a head followed by a tail, which gives you a base case and a recursive case for
free:

```lisp
(define (my-map f xs)
  (if (empty? xs)
      '()
      (cons (f (head xs)) (my-map f (tail xs)))))

(my-map (lambda (x) (* x x)) '(1 2 3 4))  ; (1 4 9 16)
```

Many of the sequence primitives work on strings too, using exactly the same
names — `head`, `tail`, `take`, `length`, `reverse`, `contains?` and friends
resolve on the type of the sequence you hand them:

```lisp
(length "hello")                          ; 5
(take 2 "hello")                          ; "he"
(reverse "abc")                           ; "cba"
```

### Sets

A set holds each member once and answers membership questions quickly. Build
one with `set`, which takes its members directly, or with `make-set`, which
takes a list:

```lisp
(set 1 2 3)                               ; #{1 2 3}
(set 1 1 2)                               ; #{1 2} — duplicates collapse
(set)                                     ; #{} — the empty set
(make-set '(1 2 2 3))                     ; #{1 2 3}
(values (set 1 2 3))                      ; back to a list of three
```

Sets print with a leading `#`, as hashmaps do. A set has no order, so the
members above are shown in a readable one — the order you actually get is
unspecified and may differ on each run. Members can be of any type, and
are compared exactly as `eq` compares them, so `1` and `1.0` are two members
rather than one:

```lisp
(length (set 1 1.0))                      ; 2
(contains? 2 (set 1 2))                   ; true
(insert 4 (set 1 2))                      ; a new set of three
(remove 1 (set 1 2))                      ; a new set of one
```

Then there is the algebra, which is the reason to reach for a set in the first
place:

```lisp
(union (set 1 2) (set 2 3))               ; #{1 2 3}
(intersection (set 1 2) (set 2 3))        ; #{2}
(difference (set 1 2 3) (set 2))          ; #{1 3}
(is-subset? (set 1) (set 1 2))            ; true
(is-disjoint? (set 1) (set 2))            ; true
```

Two sets are equal when they have the same members, however they were built:

```lisp
(eq (set 1 2) (set 2 1))                  ; true
```

Where order matters, use a list.

### Mapping, filtering, and reducing

You will not often need `my-map`, because `map`, `filter` and `reduce` are
built in. They take a function as their first argument — a `lambda`, a defined
procedure, or a primitive:

```lisp
(map square '(1 2 3))                     ; (1 4 9)
(filter (lambda (x) (> x 1)) '(1 2 3))    ; (2 3)
(reduce + 0 '(1 2 3 4))                   ; 10
(all (lambda (x) (> x 0)) '(1 2 3))       ; true
(any (lambda (x) (> x 2)) '(1 2 3))       ; true
```

`reduce` takes the function, a starting value, and the list, and calls the
function with the accumulator first and the element second. Passing a primitive
directly, as in `(reduce + 0 …)`, is idiomatic.

All five take a [set](#sets) as readily as a list, and `map` and `filter` give
back the kind they were given:

```lisp
(map (lambda (x) (* x x)) (set 1 2 3))    ; #{1 4 9} — a set
(filter (lambda (x) (> x 1)) (set 1 2 3)) ; #{2 3}
(reduce + 0 (set 1 2 3))                  ; 6
```

They compose, which is where the style earns its keep:

```lisp
(implode " " (map uppercase (words "hello there world")))
                                          ; "HELLO THERE WORLD"
```

### Recursion and tail calls

Myron has no loops. Iteration is recursion, and that is safe here because Myron
implements proper tail calls: when a recursive call is the last thing a
procedure does, it reuses the current frame instead of stacking a new one.

```lisp
(define (count-down n)
  (if (== n 0) "done" (count-down (- n 1))))

(count-down 1000000)                      ; "done" — constant stack
```

Compare it with a version that is *not* tail-recursive, because `n` is still
needed once the call returns:

```lisp
(define (sum n)
  (if (== n 0) 0 (+ n (sum (- n 1)))))

(sum 100)                                 ; 5050
(sum 100000)                              ; ERROR: Exceeded maximum stack depth
```

The second one is not a crash: it is an ordinary failure that the host receives
as a `MyronError`, and the session carries on afterwards. Raise the ceiling
with [`maximumStackDepth`](#configuration) if you need to, or rewrite the
function with an accumulator to put the call back in tail position:

```lisp
(define (sum-from acc n)
  (if (== n 0) acc (sum-from (+ acc n) (- n 1))))

(sum-from 0 1000000)                      ; 500000500000
```

### Errors

Myron reports errors rather than trapping. Overflow, division by zero, a
misused type and an unbound name all produce a diagnostic pointing at the text
responsible:

```
> (+ 1 undefined)
ERROR: Unrecognised symbol
(+ 1 undefined)
     ^^^^^^^^^
```

That is the whole language. The rest of this page is reference material.

## Language reference

### Lexical structure

**Brackets.** `(` and `)` delimit lists. An expression is either an atom or a
list of expressions.

**Integers.** `42`, `-7`, `+3`. A leading `+` or `-` is part of the number when
it is immediately followed by a digit; otherwise it is the symbol `+` or `-`.
An integer is a Swift `Int`, so 64-bit and signed on every platform Myron
currently runs on.

**Doubles.** Any numeric token containing a decimal point: `3.14`, `-0.5`.
Doubles are IEEE 754 binary64. A malformed token such as `1.2.3` is reported as
an invalid number.

**Booleans.** `true` and `false`.

**Strings.** Delimited by double quotes, and free to contain whitespace and
brackets: `"hello (world)"`, and to run across several lines — a newline
inside the quotes is part of the string. There are no escape sequences, so a
string cannot contain a `"`. An unterminated string is an error.

**Symbols.** Any token that is none of the above: `x`, `factorial`, `+`, `<=`,
`nothing?`, `my-map`. Symbols name bindings. There is no reserved character
set: brackets, whitespace and `;` end a symbol, and everything else is fair
game.

**The tick.** `'expr` abbreviates `(quote expr)`. It works anywhere, including
inside a list: `(length '(1 2 3))`.

**Comments.** `;` begins a comment that runs to the end of the line.
Semicolons inside a string literal are ordinary characters.

**Whitespace** separates tokens and is otherwise insignificant.

### Evaluation model

- **Numbers, booleans and strings** evaluate to themselves.
- **Symbols** evaluate to the value they are bound to. Lookup walks outward
  from the innermost environment and ends at the standard environment; an
  unbound symbol is an `unrecognisedSymbol` error.
- **Lists** are applications, except where the head names a special form. In
  `(f a b)`, `f`, `a` and `b` are each evaluated, left to right, and the value
  of `f` is applied to the argument values. Applying a non-callable value is an
  `expectedFunction` error, and the empty application `()` is an
  `emptyApplication` error.

Several top-level forms may appear in one program. They are evaluated in order
and the value of the last is the value of the program; the first error stops
evaluation.

User bindings shadow standard-environment names, so `(define max 9)` hides the
built-in `max`. Special form names are recognised before any lookup and so
cannot be shadowed: after `(define if 3)`, `if` still branches.

New scopes are created by a procedure call and by `let`. A `define` binds into
whichever environment is current, which means a `define` inside a procedure
body or a `let` is local to it and does not escape.

Evaluation is driven by an explicit machine whose continuation stack lives on
the heap, so recursion depth is bounded by
[`maximumStackDepth`](#configuration) rather than by the host thread's stack.
Calls in tail position — the last body of a procedure, `let`, `begin` or a
`cond` clause, and the selected branch of an `if` — do not grow that stack.

### Special forms

Nine forms are evaluated specially rather than as applications, because each
one needs to leave some part of itself unevaluated.

| Form | Shape |
|---|---|
| [`and`](#and-and-or) | `(and test …)` |
| [`begin`](#begin) | `(begin expr …)` |
| [`cond`](#cond) | `(cond (test body …) …)` |
| [`define`](#define) | `(define name value)` or `(define (name param …) body …)` |
| [`if`](#if) | `(if test consequent alternative)` |
| [`lambda`](#lambda) | `(lambda (param …) body …)` |
| [`let`](#let) | `(let ((name value) …) body …)` |
| [`or`](#and-and-or) | `(or test …)` |
| [`quote`](#quote) | `(quote expr)`, abbreviated `'expr` |

#### `define`

```lisp
(define name value)
(define (name param …) body …)
```

Binds a name in the current environment. The value form takes exactly one
expression; the procedure form is sugar for binding a `lambda`, and takes one
or more body expressions, yielding the value of the last.

```lisp
(define x 5)
(define (add2 a b) (+ a b))
(define (hypotenuse a b)
  (define (square n) (* n n))
  (sqrt (+ (square a) (square b))))
```

A `define` evaluates to a define marker naming the binding, not to the bound
value. Redefining a name in the same environment replaces the binding.

*Errors:* `unexpectedArity` for `(define x 1 2)` or a procedure form with no
body; `unexpectedType` when the signature is neither a symbol nor a list, or
when a parameter is not a symbol.

#### `if`

```lisp
(if test consequent alternative)
```

Evaluates `test`, then evaluates only the branch it selects. All three
arguments are required. The test must evaluate to a boolean — there is no
truthiness, so `(if 1 "a" "b")` is a type error. Both branches are in tail
position.

#### `cond`

```lisp
(cond (test body …) …)
```

Tries each clause in order and evaluates the bodies of the first whose test is
`true`, yielding the value of the last body. Tests after the first match are
never evaluated, and neither are the bodies of clauses that do not match.

```lisp
(cond ((< n 0) "negative")
      ((> n 0) "positive")
      (true    "zero"))
```

At least one clause is required. Each clause must be a list carrying at least a
test, and each test must evaluate to a boolean. There is no `else`: use a final
clause whose test is `true`. If no clause matches — or the matching clause has
no body — the result is `nothing`. The last body of the selected clause is in
tail position.

Clauses after the one that matches are never inspected, so a malformed clause
later in the form goes unreported.

#### `lambda`

```lisp
(lambda (param …) body …)
```

Creates a procedure that closes over the environment in which it was written.
One or more body expressions are allowed; the value of the last is returned.
Parameters must be symbols, and arity is exact at the call site.

```lisp
(lambda () 42)
(lambda (x) (* x x))
(lambda (x) (define scaled (* x 2)) (+ scaled 1))
```

#### `let`

```lisp
(let ((name value) …) body …)
```

Evaluates each binding in turn in a fresh environment, then evaluates the
bodies there, yielding the value of the last. Bindings are sequential, so a
later one may refer to an earlier one:

```lisp
(let ((x 5) (y (* x 2))) y)               ; 10
```

The binding list may be empty, but at least one body is required. Names
bound — or defined — inside a `let` do not escape it, and they shadow outer
bindings rather than replacing them. The last body is in tail position.

*Errors:* `unexpectedType` when the binding list or a binding is not a list, or
a bound name is not a symbol; `unexpectedArity` when a binding is not exactly a
name and a value.

#### `begin`

```lisp
(begin expr …)
```

Evaluates its expressions in order and yields the value of the last. `(begin)`
yields `nothing`. Unlike `let`, `begin` does not create a scope: a `define`
inside one binds into the surrounding environment. The last expression is in
tail position.

#### `and` and `or`

```lisp
(and test …)
(or  test …)
```

Both are special forms so that they can short-circuit. `and` evaluates its
tests left to right and stops at the first `false`; `or` stops at the first
`true`. Tests that are never reached are never evaluated, so
`(and false (/ 1 0))` is `false` rather than an error.

Every test that *is* reached must evaluate to a boolean. At least one test is
required. `(and t)` and `(or t)` are just `t`, checked for booleanness.

#### `quote`

```lisp
(quote expr)
'expr
```

Returns the expression as data, unevaluated. Symbols stay symbols and lists
stay lists, recursively:

```lisp
'(1 (+ 1 2))                              ; (1 (+ 1 2)) — nothing is applied
''x                                       ; (quote x)
'()                                       ; the empty list
'x                                        ; the symbol x
```

Exactly one expression may be quoted.

## Standard library reference

Every environment can see the standard environment: primitives and constants
found by symbol lookup when no user binding shadows them. Unlike special forms,
these are ordinary values — they can be passed to `map`, bound to a new name,
or shadowed.

Three rules run through everything below.

**Integers and doubles never mix.** A primitive that takes "a number" wants all
of its numeric arguments in the same domain. `(+ 1 2.5)` is a type error, not
`3.5`. Convert with `integer` or `double`.

**Errors are values.** Every failure listed here comes back to the host as a
`MyronError`, including overflow and division by zero.

**One name can cover several types.** `head` works on a list and on a string,
`get` on an alist and on a hashmap, and neither is a special case written into
the language. Each is an ordinary primitive that declares the argument types it
accepts, and the standard environment picks the one that fits the call,
preferring the most specific fit where more than one would do. A call that
matches nothing raises `unexpectedType` or `unexpectedArity` as any primitive
would; the rarer `couldNotResolve` names the shapes that would have worked.

### Comparison

Each comparison has a word form and an operator form; they are the same
function under two names.

| Primitive | Alias | Arguments | Result |
|---|---|---|---|
| `eq` | `==` | 2 values of any type | boolean |
| `neq` | `!=` | 2 values of any type | boolean |
| `gt` | `>` | 2 integers, doubles, or strings | boolean |
| `gte` | `>=` | 2 integers, doubles, or strings | boolean |
| `lt` | `<` | 2 integers, doubles, or strings | boolean |
| `lte` | `<=` | 2 integers, doubles, or strings | boolean |

```lisp
(== 3 3)                                  ; true
(eq '(1 2) '(1 2))                        ; true — element-wise, recursively
(== 1 1.0)                                ; false — different types
(> "b" "a")                               ; true — lexicographic
(<= 3 3)                                  ; true
```

Equality across types is `false` rather than an error, so `(== 1 1.0)` is
`false` — an integer is never a double. Ordering is stricter and still raises
`unexpectedType`, since there is no sensible answer to give. Equality is defined
for every type; ordering only for integers, doubles, and strings. Hashmaps
compare by content, so insertion order does not matter. A primitive equals
itself under any of its names, and a procedure equals itself but not a
separately written twin:

```lisp
(eq map map)                              ; true
(eq + +)                                  ; true
(define (f x) x)
(eq f f)                                  ; true
(eq (lambda (x) x) (lambda (x) x))        ; false — two procedures
```

### Predicates

Each predicate takes exactly one value of any type and answers `true` or
`false`. None of them fail on an unexpected type — that is the point of having
them.

| Primitive | True when the argument is |
|---|---|
| `nothing?` | `nothing` |
| `number?` | an integer or a double |
| `integer?` | an integer |
| `double?` | a double |
| `string?` | a string |
| `boolean?` | a boolean |
| `list?` | a list |
| `set?` | a set |
| `positive?` | a number greater than zero |
| `negative?` | a number less than zero |
| `zero?` | a number equal to zero |
| `finite?` | a number that is neither infinite nor `nan` |
| `infinite?` | a double that is positive or negative infinity |
| `callable?` | a procedure or a primitive — anything that can head an application |

```lisp
(nothing? (head '()))                     ; true
(integer? 1.0)                            ; false — the types stay apart
(list? '())                               ; true
(list? sqrt)                              ; false — functions match none
(positive? "x")                           ; false — non-numbers are never
```

`integer?` and `double?` do not overlap; use `number?` when either will do. The
numeric predicates answer `false` for non-numbers rather than failing —
including `finite?`, for which every integer is finite and every non-number is
not.

### Logic

| Primitive | Arguments | Result |
|---|---|---|
| `not` | 1 boolean | boolean |

```lisp
(not true)                                ; false
```

`and` and `or` are [special forms](#and-and-or), not primitives, so that they
can short-circuit. They cannot be passed to `map` or bound to another name; use
a `lambda` if you need them as values.

### Mathematics

#### Constants

| Name | Value |
|---|---|
| `pi` | `3.141592653589793`, a double |

#### Arithmetic

| Primitive | Arguments | Result |
|---|---|---|
| `+` | 2 or more numbers | sum |
| `-` | 1 number (negation) or 2 numbers (difference) | number |
| `*` | 2 or more numbers | product |
| `/` | 2 numbers | quotient |
| `mod` | 2 integers | remainder with the sign of the divisor |
| `rem` | 2 integers | remainder with the sign of the dividend |
| `pow` | 2 numbers | power |

```lisp
(+ 1 2 3 4)                               ; 10
(- 3)                                     ; -3
(- 10 4)                                  ; 6
(* 2.0 3.5)                               ; 7.0
(/ 7 2)                                   ; 3 — integer division truncates
(/ 7.0 2.0)                               ; 3.5
(mod -7 3)                                ; 2
(rem -7 3)                                ; -1
(pow 2 10)                                ; 1024
```

Division or modulo by zero is a `divisionByZero` error. Integer arithmetic that
exceeds `Int` is an `overflow` error — including inside `pow`, which computes
integer powers by repeated squaring rather than through floating point. A
negative integer exponent yields `0`, except that `(pow 1 -n)` is `1` and
`(pow -1 -n)` alternates; `(pow 0 -n)` is a `divisionByZero` error.

#### Bounds and rounding

| Primitive | Arguments | Result |
|---|---|---|
| `min` | 1 or more numbers | smallest |
| `max` | 1 or more numbers | largest |
| `abs` | 1 number | same type |
| `floor` | 1 double | double |
| `ceil` | 1 double | double |
| `round` | 1 double | double |

```lisp
(min 3 1 2)                               ; 1
(abs -5)                                  ; 5
(floor 3.7)                               ; 3.0
(round 3.5)                               ; 4.0
```

`floor`, `ceil` and `round` take doubles only and return doubles — `(floor 3)`
is a type error, and `(floor 3.7)` is `3.0`, not `3`. Reach for `integer` when
you want the other type back.

#### Roots, logarithms, and trigonometry

| Primitive | Arguments | Result |
|---|---|---|
| `sqrt` | 1 number | double |
| `log` | 1 double | base-10 logarithm |
| `ln` | 1 double | natural logarithm |
| `sin`, `cos`, `tan` | 1 double, in radians | double |
| `asin`, `acos`, `atan` | 1 double | double, in radians |
| `atan2` | 2 doubles, y then x | double, in radians |

```lisp
(sqrt 2)                                  ; 1.4142135623730951
(log 100.0)                               ; 2.0
(sin (/ pi 2.0))                          ; 1.0
(atan2 1.0 1.0)                           ; 0.7853981633974483
```

`sqrt` accepts either numeric type and always returns a double. The rest accept
doubles only.

#### Conversion

| Primitive | Arguments | Result |
|---|---|---|
| `integer` | 1 integer, double, or string | integer |
| `double` | 1 integer, double, or string | double |

```lisp
(integer 3.9)                             ; 3 — truncates toward zero
(integer "42")                            ; 42
(double 3)                                ; 3.0
(double "1.5")                            ; 1.5
```

Both are the identity on their own type. Strings are trimmed of surrounding
whitespace before conversion, and `integer` accepts a decimal string by
truncating it. A string that is not a number raises `invalidNumber`; any other
type raises `typeCastFailed`.

### Sequences

Lists and strings are both sequences, and these primitives work on either. One
name covers both: the standard environment resolves the call against the types
of the arguments, so the same name does the obvious thing in either case. A
string behaves as a sequence of one-character strings — Myron has no character
type.

Three of these reach past sequences. `length` and `empty?` also accept a
[hashmap](#hashmaps) or a [set](#sets), and `contains?` also accepts a set. The
rest do not, since neither a hashmap nor a set has an order.

| Primitive | Arguments | Result |
|---|---|---|
| `head` | 1 sequence | first element, or `nothing` if empty |
| `tail` | 1 sequence | the sequence without its first element |
| `init` | 1 sequence | the sequence without its last element |
| `last` | 1 sequence | last element, or `nothing` if empty |
| `take` | non-negative integer, sequence | the first n elements |
| `drop` | non-negative integer, sequence | all but the first n elements |
| `nth` | integer index, sequence | the element at that index |
| `length` | 1 sequence | integer |
| `empty?` | 1 sequence | boolean |
| `reverse` | 1 sequence | the sequence, reversed |
| `append` | 1 or more sequences | the sequences concatenated |
| `contains?` | value, sequence or set | boolean |

```lisp
(head '(1 2 3))                           ; 1
(head "hello")                            ; "h"
(tail '(1 2 3))                           ; (2 3)
(init '(1 2 3))                           ; (1 2)
(take 2 "hello")                          ; "he"
(drop 5 '(1 2))                           ; () — over-dropping is fine
(nth 2 '(1 2 3))                          ; 3 — indices are zero-based
(length "hello")                          ; 5
(empty? '())                              ; true
(reverse "abc")                           ; "cba"
(append '(1) '(2 3))                      ; (1 2 3)
(append "foo" "bar")                      ; "foobar"
(contains? 2 '(1 2 3))                    ; true
(contains? "ell" "hello")                 ; true — substring, not character
(contains? 2 (set 1 2))                   ; true
```

`head` and `last` return `nothing` for an empty sequence, but `nth` raises
`subscriptOutOfBounds` rather than returning `nothing`. A negative count to
`take` or `drop` raises `cannotBeNegative`; a count past the end is fine.

`append` decides which kind of sequence it is building from its first argument,
and every remaining argument must match, so lists and strings cannot be mixed.
At least one argument is required.

`contains?` compares with the same rules as `eq`, recursively, except that a
type mismatch counts as "not found" rather than failing: `(contains? "a" '(1 2))`
and `(contains? 1 '(1.0))` are both `false`. Over a string it tests for a
substring, and the empty string is contained in everything.

### Lists

These two build lists; everything else about lists is in
[Sequences](#sequences) above.

| Primitive | Arguments | Result |
|---|---|---|
| `cons` | value, list | the list with the value prepended |
| `list` | 0 or more values | a list of those values |

```lisp
(cons 1 '(2 3))                           ; (1 2 3)
(list 1 2 3)                              ; (1 2 3) — arguments are evaluated
(list)                                    ; ()
(list (+ 1 1) "two")                      ; (2 "two")
```

`cons` requires a list as its second argument. There are no dotted pairs, so
`(cons 1 2)` is a type error rather than an improper list.

Between `cons`, `list`, `append` and the sequence primitives, lists can be
built as well as taken apart, which means list utilities can be written in
Myron rather than having to be primitives:

```lisp
(define (my-filter p xs)
  (cond ((empty? xs)     '())
        ((p (head xs))   (cons (head xs) (my-filter p (tail xs))))
        (true            (my-filter p (tail xs)))))

(my-filter (lambda (x) (> x 2)) '(1 2 3 4))
                                          ; (3 4)
```

### Association lists

An association list is an ordinary list of two-element lists, each a key and a
value. Nothing declares one — any list of that shape will do — so these
primitives are a convention over lists rather than a separate type.

Every primitive here, except `key-index`, also works on a
[hashmap](#hashmaps) — resolved on the type of the collection, the way the
sequence primitives are.

| Primitive | Arguments | Result |
|---|---|---|
| `get` | key, alist | the value, or `nothing` if absent |
| `get-or` | default, key, alist | the value, or the default if absent |
| `put` | key, value, alist | the alist with the key set to the value |
| `remove` | key, alist | the alist without that key |
| `has-key?` | key, alist | boolean |
| `keys` | alist | a list of the keys, in order |
| `values` | alist | a list of the values, in order |
| `key-index` | key, alist | the position of the key, or `nothing` if absent |

```lisp
(define ages '(("ada" 36) ("alan" 41)))

(get "ada" ages)                          ; 36
(get "grace" ages)                        ; <nothing>
(get-or 0 "grace" ages)                   ; 0
(put "grace" 45 ages)                     ; (("ada" 36) ("alan" 41) ("grace" 45))
(put "ada" 37 ages)                       ; (("ada" 37) ("alan" 41))
(keys ages)                               ; ("ada" "alan")
```

The alist is always the last argument, and `get-or` takes its default first so
that the "or" reads next to the value it supplies. Nothing is mutated: `put`
and `remove` return a new list, replacing a key in place and appending a new
one at the end.

Any value is a key — a symbol, a list, a nested hashmap, even a procedure.
Keys are typed exactly as `eq` compares them, so `1` and `1.0` are two
different keys:

```lisp
(get 1 '((1.0 "double") (1 "integer")))   ; "integer"
(get '(1 2) '(((1 2) "list")))            ; "list"
(get 'a '((a "symbol")))                  ; "symbol"
```

The one value that cannot be a key is a `nan`, which is not equal to itself: an
entry stored under one could never be found again. `put` silently drops a key
holding a `nan` anywhere inside it, and leaves the alist otherwise untouched.
An infinity equals itself, so it keys like anything else, and a `nan` is
perfectly good as a *value*:

```lisp
(put (sqrt -1.0) 1 '())                   ; () — dropped
(put (list 1 (sqrt -1.0)) 1 '())          ; () — dropped, at any depth
(get "a" (put "a" (sqrt -1.0) '()))       ; nan — fine as a value
```

Storing `nothing` is a way to delete: `(put k nothing al)` is `(remove k al)`.
That is what makes `get` unambiguous — a `nothing` coming back always means the
key is absent, never that a `nothing` was stored there.

An entry that is not a two-element list raises `malformedAlist` with its index.
Lookups stop at the first match, so a malformed entry *after* the key you asked
for goes unnoticed; a successful `get` is not a promise that the whole list is
well formed. `put`
is the exception — it checks the whole list, and refuses with `duplicateKeys`
if a key appears twice. A duplicated key can still be repaired with `remove`,
which takes the first match. Invoking `put` to an existing key is legal and
operates as replacement rather than creating a duplicate.

### Hashmaps

A hashmap is a distinct type with constant-time lookup, where an
[alist](#association-lists) is a list you read from front to back. The
associative primitives are shared between them, so only the two below are
hashmap-specific.

| Primitive | Arguments | Result |
|---|---|---|
| `make-hashmap` | nothing, or 1 alist | a new hashmap |
| `keys-values` | hashmap | an alist of its entries |

```lisp
(define ages (make-hashmap '(("ada" 36) ("alan" 41))))

(get "ada" ages)                          ; 36
(get "grace" ages)                        ; <nothing>
(get-or 0 "grace" ages)                   ; 0
(has-key? "alan" ages)                    ; true
(length ages)                             ; 2
(put "grace" 45 ages)                     ; a new hashmap of three
(remove "ada" ages)                       ; a new hashmap of one
(keys-values ages)                        ; an alist of both entries
```

`make-hashmap` with no argument gives an empty one. Given an alist it converts
it, following the same rules as the alist primitives: an entry that is not a
two-element list raises `malformedAlist`, a repeated key raises `duplicateKeys`,
and an entry whose key holds a `nan` is dropped. Together with
`keys-values`, which goes the other way, the two representations convert freely:

```lisp
(eq (make-hashmap (keys-values ages)) ages)
                                          ; true
```

Everything else — [`get`, `get-or`, `put`, `remove`, `has-key?`, `keys` and
`values`](#association-lists) — is shared with alists and behaves the same way,
including `put` with `nothing` as a delete. `key-index` is alist-only: a hashmap
has no positions to report. So are the ordered sequence primitives; only
`length` and `empty?` accept a hashmap.

Keys follow the same rules as in an alist, so `1` and `1.0` are two different
keys:

```lisp
(get 1 (make-hashmap '((1.0 "double") (1 "integer"))))
                                          ; "integer"
```

Hashmaps print with a leading `#`, and compare by content rather than by
identity or order:

```lisp
(make-hashmap '(("a" 1)))                 ; #(("a" 1))
(eq (make-hashmap '(("a" 1) ("b" 2)))
    (make-hashmap '(("b" 2) ("a" 1))))    ; true
```

The order in which `keys`, `values`, `keys-values` and printing enumerate a
hashmap is unspecified, and may differ between runs. Use an alist where order
matters.

### Sets

A set is an unordered collection that holds each member once. Membership is
decided exactly as `eq` decides equality, so `1` and `1.0` are two members.

| Primitive | Arguments | Result |
|---|---|---|
| `set` | 0 or more values | a set of those values |
| `make-set` | nothing, 1 list, or 1 hashmap | a new set |
| `values` | 1 set | a list of its members |
| `insert` | value, set | the set with the value added |
| `remove` | value, set | the set without the value |
| `contains?` | value, set | boolean |
| `length` | 1 set | integer |
| `empty?` | 1 set | boolean |
| `union` | 1 or more sets | every member of any of them |
| `intersection` | 1 or more sets | the members common to all of them |
| `difference` | 2 or more sets | the first without the members of the rest |
| `symmetric-difference` | 2 sets | the members of exactly one of them |
| `is-subset?` | 2 sets | `true` if every member of the first is in the second |
| `is-strict-subset?` | 2 sets | as `is-subset?`, but not when they are equal |
| `is-superset?` | 2 sets | `true` if the first holds every member of the second |
| `is-strict-superset?` | 2 sets | as `is-superset?`, but not when they are equal |
| `is-disjoint?` | 2 sets | `true` if they share no member |

```lisp
(set 1 2 3)                               ; #{1 2 3}
(set 1 1 2)                               ; #{1 2} — duplicates collapse
(set)                                     ; #{} — the empty set
(make-set '(1 2 2 3))                     ; #{1 2 3}
(values (set 1 2 3))                      ; a list of the three members

(insert 4 (set 1 2))                      ; #{1 2 4}
(remove 1 (set 1 2))                      ; #{2}
(contains? 2 (set 1 2))                   ; true
(length (set 1 2 3))                      ; 3
(empty? (set))                            ; true
```

A set has no order, so every printed set on this page is shown with its members
in a readable order. The order you actually get is unspecified; see the note at
the end of this section.

`set` evaluates its arguments and takes each as a member, exactly as `list`
does. `make-set` takes a collection instead: given a list it takes the elements,
and given a hashmap it takes each entry as a two-element list, which is the same
shape `keys-values` produces. With no argument it gives an empty set.

```lisp
(make-set (make-hashmap '(("a" 1))))      ; #{("a" 1)}
(eq (make-set (values (set 1 2 3))) (set 1 2 3))
                                          ; true — round trips through a list
```

The algebra follows. `union` and `intersection` take one or more sets and
`difference` takes two or more, folding left to right; `symmetric-difference`
takes exactly two:

```lisp
(union (set 1 2) (set 2 3))               ; #{1 2 3}
(union (set 1) (set 2) (set 3))           ; #{1 2 3}
(intersection (set 1 2) (set 2 3))        ; #{2}
(difference (set 1 2 3) (set 2))          ; #{1 3}
(difference (set 1 2 3) (set 2) (set 3))  ; #{1}
(symmetric-difference (set 1 2) (set 2 3)); #{1 3}
```

Note that `difference` is the relative complement — the first set without the
members of the rest — and not the symmetric difference, which is the separate
primitive above.

The relations all take two sets and answer a boolean. The strict forms differ
from the plain ones only when the two sets are equal:

```lisp
(is-subset? (set 1) (set 1 2))            ; true
(is-subset? (set 1 2) (set 1 2))          ; true
(is-strict-subset? (set 1 2) (set 1 2))   ; false — equal is not strict
(is-superset? (set 1 2) (set 1))          ; true
(is-disjoint? (set 1) (set 2))            ; true
```

Sets print with a leading `#`, and compare by membership rather than by the
order they were built in:

```lisp
(set 1 2 3)                               ; #{1 2 3}
(eq (set 1 2) (set 2 1))                  ; true
```

Members follow the same rule as hashmap keys: a member holding a `nan` anywhere
inside it is dropped rather than stored, because a member that is not equal to
itself could never be found again. This applies on every path that builds a set,
including `map`:

```lisp
(length (set (sqrt -1.0) 1))              ; 1 — only 1 is stored
(values (map (lambda (x) (sqrt x)) (set -1.0 4.0)))
                                          ; (2.0)
```

The order in which `values` and printing enumerate a set is unspecified, and may
differ between runs. Use a list where order matters — and see the note on
`reduce` under [higher-order functions](#higher-order-functions).

The ordered sequence primitives do not accept a set, since a set has no
positions; only `length`, `empty?` and `contains?` do.

### Strings

These are string-specific; the sequence primitives above also work on strings.

| Primitive | Arguments | Result |
|---|---|---|
| `string` | 1 value | its printed form as a string |
| `explode` | 1 string | a list of one-character strings |
| `implode` | 1 list, or a separator string and a list | a string |
| `lowercase` | 1 string | string |
| `uppercase` | 1 string | string |
| `trim` | 1 string | string without leading or trailing whitespace |
| `lines` | 1 string | a list of strings, split on newlines |
| `words` | 1 string | a list of strings, split on whitespace |

```lisp
(string 42)                               ; "42"
(string '(1 2))                           ; "(1 2)"
(explode "abc")                           ; ("a" "b" "c")
(implode '("a" "b" "c"))                  ; "abc"
(implode "-" '("a" "b" "c"))              ; "a-b-c"
(uppercase "hi")                          ; "HI"
(trim "  hi  ")                           ; "hi"
(words "the quick  brown")                ; ("the" "quick" "brown")
```

`string` is the identity on a string and otherwise gives the value's printed
form, which makes it the way to get a number into a message. `implode` is the
inverse of `explode`, and with a separator it undoes `words` and `lines`. It
renders non-string elements the way `string` would, so `(implode "-" '(1 true))`
is `"1-true"`.

`lines` keeps empty lines; `words` discards empty runs of whitespace. A
string literal may span several lines of source, so `lines` has something to
work on — but with no escape sequence there is no way to put a newline into a
literal written on one line, and the line-based REPL cannot enter one.

### Higher-order functions

| Primitive | Arguments | Result |
|---|---|---|
| `map` | function, list or set | the results, in the kind given |
| `filter` | predicate, list or set | the elements the predicate accepted |
| `reduce` | function, initial value, list or set | the accumulated value |
| `all` | predicate, list or set | `true` if every element satisfies it |
| `any` | predicate, list or set | `true` if some element satisfies it |

```lisp
(map (lambda (x) (* x x)) '(1 2 3))       ; (1 4 9)
(filter (lambda (x) (> x 1)) '(1 2 3))    ; (2 3)
(reduce + 0 '(1 2 3 4))                   ; 10
(reduce * 1 '(1 2 3 4))                   ; 24
(all (lambda (x) (> x 0)) '(1 2 3))       ; true
(any (lambda (x) (> x 2)) '(1 2 3))       ; true
```

The function may be a `lambda`, a defined procedure, or a primitive —
`(reduce + 0 …)` passes the built-in `+` directly. `map` and `filter` call it
with one argument; `reduce` calls it with two, the accumulator first; `all` and
`any` call it with one and require a boolean back. A `filter`, `all` or `any`
predicate that returns a non-boolean is a type error.

All five also accept a [set](#sets), and `map` and `filter` give back the kind
they were given — a list maps to a list, a set to a set, including when it is
empty:

```lisp
(map (lambda (x) (* x x)) (set 1 2 3))    ; #{1 4 9}
(filter (lambda (x) (> x 1)) (set 1 2 3)) ; #{2 3}
(reduce + 0 (set 1 2 3))                  ; 6
```

Two things follow from a set holding each member once. A `map` over a set gives
back the image of the function, so one that sends two members to the same result
gives back fewer members than it was given; and a result that cannot be stored —
a `nan` — is dropped, as it would be anywhere else:

```lisp
(length (map (lambda (x) 0) (set 1 2 3))) ; 1 — every member maps to 0
(length (map (lambda (x) 0) '(1 2 3)))    ; 3 — a list keeps all three
```

A set has no order, so the order in which `reduce` folds it is unspecified. Fold
a set only with a function where that does not matter — `(reduce + 0 …)` is
fine, `(reduce - 0 …)` is not — and use a list when the order is part of the
answer.

They take nothing else. Use `explode` to reach a string's characters, and
`keys`, `values` or `keys-values` to reach a hashmap's:

```lisp
(implode (filter (lambda (c) (!= c " ")) (explode "a b c")))
                                          ; "abc"
```

`all` and `any` stop at the first element that decides the answer, so a
predicate that would fail on a later element may never run. Over the empty list
`all` is `true` and `any` is `false`, following the usual convention. All five
check that their first argument is callable before iterating, so `(all 5 '())`
is an error rather than `true`.

## Status

Myron is a young language, and version `0.1.1` should be read as an invitation
rather than a promise: the public Swift interface may still change.

Notable gaps:

- No escape sequences in string literals, so a string cannot contain a `"`, and
  a newline can only be got in by letting the literal span source lines.
- No `sort`, `range`, `zip`, `flatten`, `take-while`, `drop-while` or `foldr`.
- Hashmap and set enumeration order is unspecified, and there is no ordering
  primitive to impose one.
- Sets cannot be written as literals in Myron source; build them with `set` or
  `make-set`. There is no `powerset` or Cartesian product.
- Hashmaps cannot be written as literals in Myron source; build them with
  `make-hashmap` from an alist.
- No mutation: there is no `set!`, and no way to rebind a name in an enclosing
  environment.
- No variadic user procedures, and no default or keyword parameters.
- No dotted pairs, no `nil`-terminated cons cells; a list is a list.
- No modules, no way to load Myron source from Myron.
- No I/O of any kind in the language itself. Everything comes in and goes out
  through the host, which can supply what it wants as a
  [primitive](#defining-primitives).
- A host primitive takes between zero and six arguments; there is no variadic
  form yet.
- A host primitive receives its arguments and nothing else. There is no way for
  one to read the session's environment or evaluate source, so a primitive is a
  function of its arguments alone.
- Several operations over a value recurse on the host stack, so a deeply nested
  list or hashmap can overflow it. Rendering one with `description` is the
  shallowest limit, then hashing it — which is what using one as a hashmap key
  or a set member does — and then releasing it, since the runtime tears the
  structure down recursively as well. `eq` is the exception: it walks
  iteratively and goes far deeper than the rest. Where each limit falls depends
  on the stack of the thread the session runs on, so a value that survives on
  the main thread may not on a worker. Parsing is no longer among these: the
  parser keeps its own work stack, so bracket nesting in source is bounded by
  the heap rather than by the stack.
- `sourceHandle` is carried through tokenisation but not yet surfaced on
  errors.

## Licence

Apache 2.0 — see [LICENSE](LICENSE).
