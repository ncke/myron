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
  [`Value`](#value) · [`MyronError`](#myronerror) ·
  [Configuration](#configuration) ·
  [Lifetime and threading](#lifetime-and-threading)
- [A tour of Myron](#a-tour-of-myron)
- [Language reference](#language-reference)
  — [Lexical structure](#lexical-structure) ·
  [Evaluation model](#evaluation-model) · [Special forms](#special-forms)
- [Standard library reference](#standard-library-reference)
  — [Comparison](#comparison) · [Predicates](#predicates) ·
  [Logic](#logic) · [Mathematics](#mathematics) · [Sequences](#sequences) ·
  [Lists](#lists) ·
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
  sequences, lists, strings, and the higher-order staples (`map`, `filter`,
  `reduce`, `all`, `any`).
- Sequence primitives that work on both lists and strings, dispatched on the
  argument's type: `(length '(1 2 3))` and `(length "abc")` are both `3`.
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
   *       .        *
      |\/| \ / |_) / \ |\ |  .
  .   |  |  |  | \ \_/ | \|
        *        .       *

      version 0.1.0

Ready.
> (+ 1 2)
3
> (map (lambda (x) (* x x)) '(1 2 3))
(1 4 9)
```

The REPL reads one line at a time, so keep each entry on a single line.
Definitions persist for the life of the process.

To use Myron in your own project, add it to your package dependencies and
depend on the `Myron` library product:

```swift
dependencies: [
    .package(url: "https://github.com/ncke/myron.git", from: "0.1.0")
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
its configuration, a result, the `Value` enum, `MyronError`, and the package
version. The `myron-repl` executable is itself just another host of the
library, in a few dozen lines of Swift.

```swift
import Myron

let session = MyronSession()
let result = session.eval("(+ 1 2)")      // .success(.integer(3))

print(Myron.version)                      // 0.1.0
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

### `MyronResult`

`eval` returns a `MyronResult`, a three-case enum:

```swift
public enum MyronResult {
    case success(Value)
    case failure([MyronError])
    case nothing
}
```

```swift
switch session.eval(source) {

case .success(let value):
    print(value)                          // Value is CustomStringConvertible

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
evaluation failure always holds exactly one. There is one convenience property:

```swift
if session.eval(source).isFailure { /* ... */ }
```

### `Value`

`Value` is an enum covering every kind of Myron value:

```swift
public enum Value {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case string(String)
    case symbol(String)
    case list([Value])
    case nothing
    case procedure(Procedure)             // a lambda or a defined procedure
    case primitive(Primitive)             // a built-in function
    case higherOrder(HigherOrder)         // map, filter, reduce
    case higherProbe(HigherProbe)         // all, any
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

`Value` conforms to `CustomStringConvertible`, and its `description` renders a
value the way Myron prints it: lists in brackets, strings in quotes, callables
as `<procedure>` or `<primitive>`, and the absence of a value as `<nothing>`.

Every value also reports a `Value.Kind` — a plain, `Equatable` enum with no
associated values — which is what error messages talk about and what you want
when you only care about the type:

```swift
guard value.kind == .list else { return nil }        // not a list
```

Note that `Value` is not `Equatable`: comparing two values means comparing them
in Myron with `eq`, or matching on the cases yourself.

### `MyronError`

```swift
public struct MyronError: Error, Sendable {
    public let reason: Reason             // what went wrong
    public let location: Location?        // where, a Range<Int> of offsets
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
| `cannotBeNegative` | A count that must be non-negative was not — `(take -1 xs)`. |
| `divisionByZero` | `/`, `mod`, or `rem` was given a zero divisor. |
| `emptyApplication` | The form `()` was evaluated. |
| `exceededMaximumStackDepth(Int)` | Recursion passed the configured limit; carries the depth reached. |
| `expectedExpressionAfterTick` | A `'` was not followed by an expression. |
| `expectedFunction(Value.Kind)` | The head of an application was not callable. |
| `expectedQuote` | A string literal was never closed. |
| `expectedRightBracket` | A list was never closed. |
| `incomparableTypes` | `gt`/`lt` and friends were given types with no ordering. |
| `inequatableTypes` | `eq` was given types with no equality — notably `nothing`. |
| `internalError(String)` | An invariant inside the interpreter broke. Please report these. |
| `invalidNumber` | A numeric token or cast could not be read as a number. |
| `overflow` | Integer arithmetic exceeded `Int`. |
| `subscriptOutOfBounds(Int, Int)` | An `nth` index fell outside the sequence; carries index and length. |
| `typeCastFailed(Value.Kind, Value.Kind)` | `integer` or `double` was applied to a value it cannot convert. |
| `unexpectedArity(Int, IntegerExpectation)` | Wrong number of arguments; carries what was given and what was wanted. |
| `unexpectedType(Value.Kind?, Set<Value.Kind>)` | Wrong type of argument; carries what was given and what was acceptable. |
| `unimplementedFeature` | Reserved for primitives that are declared but not yet implemented. Nothing raises it today. |
| `unmatchedParenthesis` | A `)` appeared with no opening `(`. |
| `unrecognisedSymbol` | A symbol had no binding. |

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
registry breaks those cycles at teardown. The practical consequence is that you
should not hold on to a `.procedure` value beyond the life of the session that
produced it — extract the data you need while the session is alive.

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

Myron has integers, doubles, booleans, strings, symbols, lists, and `nothing`.

```lisp
42                                        ; integer
3.14                                      ; double
true                                      ; boolean
"hello"                                   ; string
'x                                        ; symbol
'(1 2 3)                                  ; list
```

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
list, and it is deliberately awkward to work with: comparing it is an error, so
test for it with `nothing?`.

```lisp
(head '())                                ; <nothing>
(nothing? (head '()))                     ; true
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
names — `head`, `tail`, `take`, `length`, `reverse`, `contains` and friends
dispatch on the type of the sequence you hand them:

```lisp
(length "hello")                          ; 5
(take 2 "hello")                          ; "he"
(reverse "abc")                           ; "cba"
```

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

Two rules run through everything below.

**Integers and doubles never mix.** A primitive that takes "a number" wants all
of its numeric arguments in the same domain. `(+ 1 2.5)` is a type error, not
`3.5`. Convert with `integer` or `double`.

**Errors are values.** Every failure listed here comes back to the host as a
`MyronError`, including overflow and division by zero.

### Comparison

Each comparison has a word form and an operator form; they are the same
function under two names.

| Primitive | Alias | Arguments | Result |
|---|---|---|---|
| `eq` | `==` | 2 values of the same type | boolean |
| `neq` | `!=` | 2 values of the same type | boolean |
| `gt` | `>` | 2 integers, doubles, or strings | boolean |
| `gte` | `>=` | 2 integers, doubles, or strings | boolean |
| `lt` | `<` | 2 integers, doubles, or strings | boolean |
| `lte` | `<=` | 2 integers, doubles, or strings | boolean |

```lisp
(== 3 3)                                  ; true
(eq '(1 2) '(1 2))                        ; true — element-wise, recursively
(> "b" "a")                               ; true — lexicographic
(<= 3 3)                                  ; true
```

Comparing different types is an error rather than `false`, so `(== 1 1.0)` does
not evaluate. Equality is defined for integers, doubles, booleans, strings,
symbols, and lists; ordering for integers, doubles, and strings. Comparing
`nothing` with anything, including itself, raises `inequatableTypes` — use
[`nothing?`](#predicates) instead.

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
| `positive?` | a number greater than zero |
| `negative?` | a number less than zero |
| `zero?` | a number equal to zero |

```lisp
(nothing? (head '()))                     ; true
(integer? 1.0)                            ; false — the types stay apart
(list? '())                               ; true
(list? sqrt)                              ; false — functions match none
(positive? "x")                           ; false — non-numbers are never
```

`nothing?` is the only way to inspect a `nothing`, since comparing one is an
error. `integer?` and `double?` do not overlap; use `number?` when either will
do. The three numeric predicates answer `false` for non-numbers rather than
failing.

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

Lists and strings are both sequences, and these primitives work on either. They
dispatch on the type of the sequence argument, so the same name does the
obvious thing in both cases. A string behaves as a sequence of one-character
strings — Myron has no character type.

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
| `contains` | value, sequence | boolean |

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
(contains 2 '(1 2 3))                     ; true
(contains "ell" "hello")                  ; true — substring, not character
```

`head` and `last` return `nothing` for an empty sequence, but `nth` raises
`subscriptOutOfBounds` rather than returning `nothing`. A negative count to
`take` or `drop` raises `cannotBeNegative`; a count past the end is fine.

`append` decides which kind of sequence it is building from its first argument,
and every remaining argument must match, so lists and strings cannot be mixed.
At least one argument is required.

`contains` compares with the same rules as `eq`, recursively, except that a
type mismatch counts as "not found" rather than failing: `(contains "a" '(1 2))`
and `(contains 1 '(1.0))` are both `false`. Over a string it tests for a
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
| `map` | function, list | a list of the results |
| `filter` | predicate, list | the elements the predicate accepted |
| `reduce` | function, initial value, list | the accumulated value |
| `all` | predicate, list | `true` if every element satisfies it |
| `any` | predicate, list | `true` if some element satisfies it |

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

Unlike the sequence primitives, these take lists only. Use `explode` to reach a
string's characters:

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

Myron is a young language, and version `0.1.0` should be read as an invitation
rather than a promise: the public Swift interface may still change.

Notable gaps:

- No escape sequences in string literals, so a string cannot contain a `"`, and
  a newline can only be got in by letting the literal span source lines.
- No `sort`, `range`, `zip`, `flatten`, `take-while`, `drop-while` or `foldr`.
- No mutation: there is no `set!`, and no way to rebind a name in an enclosing
  environment.
- No variadic user procedures, and no default or keyword parameters.
- No dotted pairs, no `nil`-terminated cons cells; a list is a list.
- No modules, no way to load Myron source from Myron.
- No I/O of any kind. Everything comes in and goes out through the host.
- The parser is recursive over the host stack, so source nested thousands of
  brackets deep can overflow it before evaluation begins.
- `sourceHandle` is carried through tokenisation but not yet surfaced on
  errors.

## Licence

Apache 2.0 — see [LICENSE](LICENSE).
