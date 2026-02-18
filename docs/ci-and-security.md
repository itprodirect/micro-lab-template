# CI & Security

> This document defines the CI pipelines and security defaults for the `micro-lab-template` repo and every repo it generates. The philosophy: **CI that can't silently pass while broken, security defaults that don't require opt-in.**

---

## CI architecture

There are two layers of CI: checks for this template repo, and checks baked into every generated repo.

### Layer 1: Template repo CI (this repo)

Three workflows run on push to `main` and on every PR:

#### `ci-selftest.yml`

Runs `scripts/selftest.sh`, which iterates every template and runs the language-appropriate lint + test commands.

```yaml
# Trigger: push to main, any PR
# Runner: ubuntu-latest
# Steps:
#   1. Checkout
#   2. Install toolchains (rustup, go, python, node)
#   3. Run: bash scripts/selftest.sh
```

`selftest.sh` must exit non-zero if ANY template fails ANY check. No partial passes.

#### `ci-templates.yml`

Matrix strategy — one job per language. Path-filtered so Rust checks only run when `templates/rust/**` changes.

```yaml
strategy:
  matrix:
    lang: [rust, go, python, ts]
  fail-fast: false          # Don't cancel other languages if one fails

# Path filter per language:
#   rust:   templates/rust/**
#   go:     templates/go/**
#   python: templates/python/**
#   ts:     templates/ts/**
```

Each matrix job runs:

| Language | Format | Lint | Test |
|----------|--------|------|------|
| Rust | `cargo fmt --all -- --check` | `cargo clippy -- -D warnings` | `cargo test --workspace` |
| Go | `gofmt -l .` (fail if output) | `go vet ./...` | `go test ./...` |
| Python | `ruff format --check .` | `ruff check .` | `pytest` |
| TypeScript | `prettier --check .` | `eslint .` | `vitest run` (or `tsc --noEmit`) |

**Important:** Linters run with **warnings-as-errors**. `clippy` uses `-D warnings`. `ruff` uses default rules. `eslint` uses recommended config. No silent warnings accumulating.

#### `ci-generator.yml`

Tests the generator script itself:

```yaml
# Steps:
#   1. Checkout
#   2. Run: bash scripts/new-repo.sh --lang rust --name ci-test-repo
#   3. Verify: grep -r '__[A-Z_]*__' out/ci-test-repo (must find nothing)
#   4. Run: cd out/ci-test-repo && cargo test --workspace
#   5. Repeat for go (at minimum)
```

This catches two classes of bugs: broken placeholder replacement, and templates that don't actually compile after generation.

### Layer 2: Generated repo CI (what every new repo gets)

Every generated repo includes a `.github/workflows/ci.yml` from the shared template. It runs:

1. Format check
2. Lint (warnings-as-errors)
3. Tests
4. (Optional) Docker build verification

The workflow file is language-specific and copied from the template during generation.

---

## Security defaults

### What every generated repo gets automatically

#### 1. Dependabot

Every generated repo includes `.github/dependabot.yml` configured for:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
  # Language-specific ecosystem added by generator:
  # - cargo (Rust)
  # - gomod (Go)
  # - pip (Python)
  # - npm (TypeScript)
```

**Why:** Dependency updates are the single highest-ROI security practice. Dependabot catches known vulnerabilities in dependencies before they become incidents.

#### 2. SECURITY.md

Every generated repo includes a `SECURITY.md` with vulnerability reporting instructions. This is a GitHub-recognized file that enables the Security tab features.

#### 3. .gitignore with secrets patterns

Every `.gitignore` includes:

```
# Secrets — never commit these
.env
.env.local
.env.*.local
*.pem
*.key
*.p12
*credentials*
*secret*
```

#### 4. .env.example (not .env)

Templates include `.env.example` with annotated variables and safe placeholder values. The actual `.env` is gitignored. This prevents accidental secret commits while documenting what config is needed.

#### 5. No secrets in CI

Generated CI workflows do NOT reference any secrets by default. Templates work with zero secrets configured. If a downstream repo needs secrets (API keys for integration tests, deploy tokens), those are added manually — never baked into the template.

#### 6. CODEOWNERS

Generated repos include `.github/CODEOWNERS` so PRs require review from designated owners.

---

## Security checks in CI

### What's enforced now (v1)

| Check | How | Language |
|-------|-----|----------|
| Dependency audit | `cargo audit` | Rust |
| Dependency audit | `govulncheck ./...` | Go |
| Dependency audit | `pip-audit` | Python |
| Dependency audit | `npm audit` | TypeScript |
| Format enforcement | See table above | All |
| Lint (warnings-as-errors) | See table above | All |
| No secrets in repo | `.gitignore` patterns | All |

### What's deferred to later versions

These are valuable but not worth the complexity in v1:

| Check | Why deferred |
|-------|-------------|
| SBOM generation | Useful for enterprise, overkill for learning repos |
| SLSA provenance | Same — add when publishing artifacts |
| Container image scanning | Add when Docker images are pushed to a registry |
| SAST (CodeQL, Semgrep) | Add per-repo when codebase is large enough to benefit |
| Signed commits | Useful but adds friction for solo/small-team work |
| Branch protection rules | Can't be set by template — document as a manual step |

---

## Blast radius defaults

"Blast radius" means: if something goes wrong, how much damage can it do?

### Principle: minimize blast radius by default

1. **No wildcard permissions in CI.** Workflows use minimal `permissions:` blocks.

   ```yaml
   permissions:
     contents: read    # Not write
   ```

2. **Pin action versions by SHA, not tag.** Tags can be moved; SHAs can't.

   ```yaml
   # Good
   - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

   # Bad
   - uses: actions/checkout@v4
   ```

   Dependabot will still propose updates with the new SHA.

3. **Docker containers run as non-root.** Every template Dockerfile includes:

   ```dockerfile
   RUN addgroup --system app && adduser --system --ingroup app app
   USER app
   ```

4. **No `latest` tags in FROM.** Dockerfiles pin specific versions:

   ```dockerfile
   FROM rust:1.83-slim AS builder    # Not rust:latest
   ```

5. **Fail closed.** If a check can't determine safety, it fails. Selftest exits non-zero on any ambiguity. CI does not have `continue-on-error: true`.

---

## Adding security checks to a generated repo

When a generated repo matures beyond a learning exercise:

### Step 1: Enable GitHub security features

In the repo's Settings → Security:
- Enable Dependabot alerts (already configured via dependabot.yml)
- Enable secret scanning
- Enable code scanning (CodeQL) for supported languages

### Step 2: Add branch protection

On `main`:
- Require PR reviews (1 reviewer minimum)
- Require status checks to pass
- Require branches to be up to date

### Step 3: Add language-specific audit to CI

Add the appropriate audit command to the repo's CI workflow (see table above). The template includes these as commented-out steps that can be uncommented when ready.

---

## File reference

| File | Location | Purpose |
|------|----------|---------|
| `ci-selftest.yml` | `.github/workflows/` | Tests all templates in this repo |
| `ci-templates.yml` | `.github/workflows/` | Matrix CI per language with path filters |
| `ci-generator.yml` | `.github/workflows/` | Tests the generator produces valid repos |
| `dependabot.yml` | `.github/` | Keeps this repo's Actions up to date |
| `selftest.sh` | `scripts/` | Runs lint + test for every template |
| `SECURITY.md` | `templates/_shared/` | Vulnerability reporting template |
| `.env.example` | `templates/_shared/` | Documents required config without leaking secrets |
