# Principles

> These are the design principles for `micro-lab-template` and every repo it generates. When making a decision and the docs don't cover it, apply these principles.

---

## 1. Portable blocks, not monoliths

Every reusable component is a small, importable library module with a defined contract. Blocks are portable across repos, across projects, across teams. A block from `rust-security-toolkit` can be used in `psec-baseline-hunter` without modification.

**In practice:** Follow the [block contract](./block-contract.md). If you can't import it as a library, it's not a block.

---

## 2. Low blast radius by default

Every default should minimize damage when something goes wrong. CI fails closed. Docker runs as non-root. Secrets never touch the repo. Permissions are minimal.

**In practice:** When choosing between "convenient but risky" and "slightly more work but safe," choose safe. Convenience can be added later; trust can't be rebuilt.

---

## 3. Tests by default, not by heroism

If it takes extra effort to add tests, the template is broken. Tests should be wired up before the first line of application code is written. CI should be green before any features exist.

**In practice:** Every template ships with at least one passing test. `selftest.sh` runs in CI. A generated repo has tests working on the first commit.

---

## 4. Boring technology for infrastructure, interesting technology for learning

The template repo itself, the generator, the CI — these should use the most boring, reliable tools available. Bash, not a custom Rust CLI. YAML, not a custom DSL. Standard GitHub Actions, not self-hosted runners.

The generated repos are where you experiment with Mojo, Zig, Elixir, WASM. The scaffolding that creates those repos should never be the thing that breaks.

**In practice:** `scripts/new-repo.sh` is bash. `selftest.sh` is bash. CI uses official GitHub Actions. Templates use standard build tools for each language.

---

## 5. Works on Windows (Git Bash), works in CI (Ubuntu), works everywhere

The primary development environment is Git Bash on Windows. The CI environment is Ubuntu. The generated repos may run on Mac, Linux, or in containers. All three must work without special casing.

**In practice:**
- `.gitattributes` enforces LF line endings everywhere
- Scripts use `#!/usr/bin/env bash`, not `#!/bin/bash`
- No `make` dependency (not reliably available on Windows)
- No symlinks (Git Bash on Windows handles them poorly)
- Path separators use forward slashes in scripts
- No reliance on GNU-specific flags for core utilities

---

## 6. Generate, don't copy-paste

If you're manually copying files between repos and doing find-and-replace, the generator is missing a feature. The cost of adding a placeholder to the generator is small; the cost of forgetting to update one of ten repos is large.

**In practice:** Every file in a generated repo should come from either `templates/_shared/` or `templates/<lang>/`. Manual post-generation edits should be rare and documented.

---

## 7. Documentation is the product

The README, the block contract, the session log — these aren't afterthoughts. They're what make the difference between "a folder of code" and "a tool someone can use." If a new contributor can't figure out how to use this repo in under five minutes by reading the docs, the docs are broken.

**In practice:**
- Every block has a README with a usage example
- Every generated repo has a README that answers: what, why, how
- Decisions are logged in `SESSION_LOG.md`
- The block contract is the first document any contributor reads

---

## 8. AI agents are first-class contributors

Claude Code and Codex are active participants in building, testing, and maintaining these repos. The repo structure, docs, and conventions are designed to be parseable and actionable by AI agents, not just humans.

**In practice:**
- `AGENTS.md` tells AI agents how to behave in this repo
- `TASKS.md` gives ordered, unambiguous implementation steps
- File structure is consistent and predictable
- Block contract provides checkable rules, not vibes
- Comments explain "why," not "what" (agents can read the code)

---

## 9. Ship small, compound often

Each phase of work should produce something that works independently. Don't wait for all four language templates before testing the generator. Don't wait for perfect CI before committing. Get Rust + Go working, wire up CI, validate, then add Python and TypeScript.

**In practice:**
- Rust and Go templates ship first
- Generator works with two languages before adding more
- CI is green before adding complexity
- Each phase has a clear "Definition of Done"

---

## 10. Learn by building, not by reading

These repos exist at the intersection of practical tooling and learning. Every template should be simple enough to learn from but real enough to actually use. A "hello world" that just prints a string teaches nothing about structure. A config + logging + error handling foundation teaches patterns that transfer to every real project.

**In practice:**
- Templates include realistic blocks, not toy examples
- Labs demonstrate actual composition, not isolated function calls
- The block contract teaches library design principles regardless of language
- Session logs capture what you learned, not just what you built
