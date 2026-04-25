# Project conventions for Claude

## No thin wrappers

Do not introduce thin wrappers — methods, helper modules, or `let` blocks whose
entire body is a single expression that delegates to another method or returns
another expression unchanged.
