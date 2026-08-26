# Myron

Myron is a small Lisp-like language implemented in Swift.

```lisp
(define (factorial n) (if (== n 0) 1 (* n (factorial (- n 1)))))

(factorial 10)                  ; 3628800

(define (square x) (* x x))
(map square '(1 2 3 4))         ; (1 4 9 16)

(reduce + 0 (filter (lambda (x) (> x 2)) '(1 2 3 4 5)))
                                ; 12
```

## Features.

- Classic s-expression syntax with `quote` and the `'` tick abbreviation.
- Lexically scoped closures with currying through `lambda`.
- A standard environment of comparison, logic, mathematics, list, and
  higher-order primitives (`map`, `filter`, `reduce`).
- Strict, coercion-free numerics: integers and doubles never mix silently.
- Error reporting with source locations and caret diagnostics.
- No dependencies.

## Getting started.

Myron is a Swift package (Swift 6). Build and test with:

```bash
swift build
swift test
```

Take Myron for a spin in the REPL:

```bash
swift run myron-repl
```

To embed Myron, add the package as a dependency and evaluate source through a
session:

```swift
import Myron

let session = MyronSession()
let result = session.eval("(+ 1 2)")    // .success(.integer(3))
```

## Documentation.

- [The Myron language](docs/language.md) — syntax, evaluation model, and
  special forms.
- [Standard library](docs/standard-library.md) — every built-in primitive,
  with signatures and examples.
- [Embedding Myron](docs/embedding.md) — hosting the interpreter from Swift.

## Status.

Myron is a young language.

Notable gaps and known issues:
- No comments yet, `;` has no special meaning to the lexer.
- Lists can be taken apart (`head`, `tail`, etc) but not yet built up: there is
  no `cons`, `list`, or `append`.
- `and` and `or` are ordinary primitives, their arguments are evaluated
  eagerly rather than short-circuited.
- Arithmetic overflow and very deep recursion are not yet trapped by the
  interpreter and will crash the host process.

## Licence.

Apache 2.0 — see [LICENSE](LICENSE).
