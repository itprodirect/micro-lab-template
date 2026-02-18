# micro-lab-template — Gap Analysis & Enhanced Plan

## Executive Summary

The session plan is solid in its core structure. The phased approach, the "boring but compounding" philosophy, and the generator concept are all right. What's missing falls into three categories: **things that will bite you at scale** (when you're scaffolding your 5th repo), **things your downstream repos actually need** (based on the LEGO blocks JSX), and **things that make the template genuinely portable** across your Windows + CI + team workflow.

Below is everything I'd add or change, organized by impact.

---

## 1. The Block Contract Is Undefined

This is the single biggest gap. The plan says each template has "1 reusable block" but never defines **what makes something a block**. When you later scaffold `python-llm-blocks` or `rust-security-toolkit`, you need a consistent answer to:

- What interface does every block expose?
- How does a lab discover and import a block?
- How do blocks declare their dependencies?

### What to add

Create a `docs/block-contract.md` that defines the minimum for every language:

```
Every block MUST:
  1. Expose a public init/new function that accepts a Config
  2. Use structured logging (not raw println/print)
  3. Return typed errors (not panics/exceptions)
  4. Include a README.md with: purpose, usage example, dependencies
  5. Have at least one test that runs without network access

Every block SHOULD:
  6. Be usable as a library (importable, not just a CLI)
  7. Accept configuration via env vars OR config file OR function args
  8. Export a version constant/function
```

This contract is what makes blocks composable across repos. Without it, your `go-api-blocks` JWT middleware and your `rust-security-toolkit` TLS checker will end up with incompatible config patterns.

---

## 2. Missing: Config & Secrets Pattern

Every single repo in your LEGO blocks JSX needs configuration (API keys, endpoints, feature flags). The templates should bake in a standardized approach from day one.

### What to add per template

- `.env.example` with annotated variables
- A `config` block that loads from: env vars → `.env` file → config file → defaults (in that priority order)
- `.env` in `.gitignore` (already implied, but enforce it)

### Why this matters

Your `python-llm-blocks` needs provider API keys. Your `go-api-blocks` needs JWT secrets. Your `terraform-aws-modules` needs AWS credentials. If each repo invents its own config loading, you lose composability.

### Concrete additions to templates

| Language | Config approach |
|----------|----------------|
| Rust | `config` crate with `dotenvy` |
| Go | `envconfig` or `viper` (but keep it light — `os.Getenv` + `.env` loader) |
| Python | `pydantic-settings` (you already use Pydantic from the LLM blocks plan) |
| TypeScript | `zod` for schema (already in plan) + `dotenv` for loading |

---

## 3. Missing: Error Handling Pattern

The plan mentions "config + logging" as the example block, but says nothing about errors. Every language handles errors differently, and if you don't standardize this in the template, each generated repo will diverge.

### What to add per template

A thin error module/type in the blocks:

| Language | Pattern |
|----------|---------|
| Rust | Custom `Error` enum implementing `std::error::Error` + `thiserror` |
| Go | Sentinel errors + `fmt.Errorf` with `%w` wrapping |
| Python | Custom exception hierarchy inheriting from a base `BlockError` |
| TypeScript | Typed `Result<T, E>` pattern or custom error classes |

Include one test per template that verifies error propagation (a lab that handles a block error gracefully).

---

## 4. Missing: Docker / Containerization

The plan targets Git Bash on Windows and GitHub Actions ubuntu runners. But your downstream repos (OpenClaw, go-api-blocks, the Terraform modules) will all need containers. Bake this in now.

### What to add

Each template gets a `Dockerfile` (or `Containerfile`) that:

1. Uses multi-stage builds (build stage + minimal runtime)
2. Runs as non-root
3. Has a health check where applicable

Also add a `.dockerignore` to the template baseline files.

The generator should include a `--docker` flag (default true) that includes these.

### Why now, not later

If you add Docker later, you'll retrofit 5+ repos. If the template includes it from day one, every repo gets it for free.

---

## 5. Missing: `Justfile` or `Taskfile` as Cross-Platform Task Runner

The plan says "don't depend on make" — correct. But then it only offers raw bash scripts. The problem: your labs and blocks will accumulate common commands (build, test, lint, fmt, run), and raw bash invocations get unwieldy.

### Recommendation: `just` (justfile)

[`just`](https://github.com/casey/just) is a command runner that works on Windows, Mac, and Linux. It's a single binary, no dependencies.

```just
# justfile

# Run all checks
check: fmt lint test

# Format code
fmt:
    cargo fmt --all

# Lint
lint:
    cargo clippy -- -D warnings

# Run tests
test:
    cargo test --workspace

# Run the lab
run lab="lab_cli":
    cargo run -p {{lab}}
```

Each template gets a `justfile` with the language-appropriate commands. Your generator replaces `__REPO_NAME__` in the justfile too.

### Fallback

If you don't want the `just` dependency, at minimum add a `scripts/dev.sh` per template that wraps common commands with a simple case statement:

```bash
#!/usr/bin/env bash
case "$1" in
  fmt)   cargo fmt --all ;;
  lint)  cargo clippy -- -D warnings ;;
  test)  cargo test --workspace ;;
  check) "$0" fmt && "$0" lint && "$0" test ;;
  *)     echo "Usage: $0 {fmt|lint|test|check}" ;;
esac
```

---

## 6. Missing: Pre-commit Hooks

Linting should catch problems *before* they hit CI, not 3 minutes later when Actions fails. This is especially important for your Windows workflow where round-trips to GitHub are slow.

### What to add

A `scripts/setup-hooks.sh` that installs a git pre-commit hook running fmt + lint:

```bash
#!/usr/bin/env bash
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
set -e
echo "Running pre-commit checks..."
# Language-specific checks injected by generator
__PRE_COMMIT_COMMANDS__
EOF
chmod +x .git/hooks/pre-commit
```

The generator replaces `__PRE_COMMIT_COMMANDS__` with the language-appropriate checks. Alternatively, if you adopt `just`, the hook just runs `just check`.

---

## 7. Missing: SECURITY.md + Vulnerability Reporting

You're building security tooling. Every generated repo should have a `SECURITY.md` that tells people how to report vulnerabilities. This is also a GitHub-recognized file that enables the "Security" tab features.

### What to add to baseline files (Phase 1)

```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please email security@__ORG__.com
or open a private security advisory on this repository.

Do NOT open a public issue for security vulnerabilities.

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | ✅        |
```

The generator replaces `__ORG__` as it does for other placeholders.

---

## 8. Missing: CHANGELOG / Versioning Strategy

Templates will evolve. When you update the Rust template to add better error handling, repos generated from the old template need a way to know they're outdated and what changed.

### What to add

1. A `CHANGELOG.md` in the template root that tracks template-level changes
2. A `__TEMPLATE_VERSION__` placeholder (e.g., `0.1.0`) that the generator stamps into generated repos
3. A `.template-version` file in generated repos so you can later build a `scripts/check-upstream.sh` that diffs against the current template

This is low effort now, high value later when you have 10 repos and want to propagate a CI improvement.

---

## 9. Generator Improvements

The `new-repo.sh` design is good but missing several practical things:

### 9a. Add `--dry-run` flag

Before creating anything, show what would be created/replaced. Essential for debugging placeholder replacement on Windows.

### 9b. Add `--no-git` flag

Sometimes you want to scaffold into an existing repo or just inspect the output. Don't force `git init`.

### 9c. Add `--blocks` flag for selective inclusion

As your block library grows, you'll want: `--blocks config,logging,errors` instead of always getting everything. For v1, keep the default "include all blocks," but design the flag now.

### 9d. Validate prerequisites

Before running, check that required tools exist:

```bash
check_prereqs() {
  local lang="$1"
  case "$lang" in
    rust)   command -v cargo >/dev/null || die "cargo not found" ;;
    go)     command -v go >/dev/null    || die "go not found" ;;
    python) command -v python3 >/dev/null || die "python3 not found" ;;
    ts)     command -v node >/dev/null  || die "node not found" ;;
  esac
}
```

### 9e. Test the generator itself

`selftest.sh` tests the templates but not the generator. Add a test that:

1. Runs `new-repo.sh --lang rust --name test-output --dry-run`
2. Verifies no `__PLACEHOLDER__` strings remain in the output
3. Verifies expected files exist

---

## 10. CI Improvements

### 10a. Add a matrix strategy

Instead of separate `ci-template-rust.yml`, `ci-template-go.yml`, etc., use a single workflow with a matrix:

```yaml
name: Template CI
on:
  push:
    paths: ['templates/**']
  pull_request:
    paths: ['templates/**']

jobs:
  test-template:
    strategy:
      matrix:
        lang: [rust, go, python, ts]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test template
        run: bash scripts/selftest.sh ${{ matrix.lang }}
```

This is cleaner, easier to maintain, and adding a new language is one line in the matrix.

### 10b. Add a generator integration test to CI

```yaml
  test-generator:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate and validate
        run: |
          bash scripts/new-repo.sh --lang rust --name ci-test-repo
          cd out/ci-test-repo
          # Verify no unreplaced placeholders
          ! grep -r '__[A-Z_]*__' . || exit 1
          # Run the generated repo's tests
          cargo test
```

### 10c. Add Windows runner test

Since you develop on Windows, add one job that runs on `windows-latest` to catch path separator and line ending issues:

```yaml
  test-windows:
    runs-on: windows-latest
    defaults:
      run:
        shell: bash
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/selftest.sh
```

---

## 11. Template Content Improvements

### 11a. Each template needs a generated README

The templates currently don't mention a README. Each `templates/<lang>/` should include a `README.md` with placeholders:

```markdown
# __REPO_NAME__

> Generated from [micro-lab-template](https://github.com/__ORG__/micro-lab-template) v__TEMPLATE_VERSION__

## Quick Start

\`\`\`bash
# Run tests
__TEST_COMMAND__

# Run the lab
__RUN_COMMAND__
\`\`\`

## Structure

- `__BLOCKS_DIR__/` — Reusable components
- `__LABS_DIR__/` — Experiments and applications that compose blocks

## Adding a new block

1. Create a new module in `__BLOCKS_DIR__/`
2. Follow the [block contract](https://github.com/__ORG__/micro-lab-template/blob/main/docs/block-contract.md)
3. Add tests
4. Use it in an existing or new lab
```

### 11b. Add a `.github/CODEOWNERS` to generated repos

If you're using these for consulting clients or team projects:

```
# Default owner
* @__ORG_OWNER__
```

### 11c. Add `.github/pull_request_template.md`

Keep it minimal:

```markdown
## What changed

## Why

## Checklist
- [ ] Tests pass
- [ ] Lint clean
- [ ] Block contract followed (if adding/modifying a block)
```

---

## 12. Alignment with Your LEGO Blocks Roadmap

Looking at your JSX visualization, there are specific needs the current template plan doesn't cover:

### 12a. Python template needs `pyproject.toml`, not `setup.py`

Your python-llm-blocks and python-data-pipeline-blocks will both need modern Python packaging. Use `pyproject.toml` with `hatchling` or `setuptools` backend. Include dependency groups for dev vs. production.

### 12b. Rust template should use workspace from the start

Your rust-security-toolkit has 6 blocks. The template's `crates/blocks/` + `crates/lab_cli/` structure is right, but make sure the `Cargo.toml` workspace configuration is set up to easily add more crates:

```toml
[workspace]
members = ["crates/*"]
resolver = "2"

[workspace.dependencies]
# Shared dependencies go here so versions stay in sync
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
```

### 12c. Go template should include `Makefile` alternative

Go projects conventionally use Makefiles. Include one even if you prefer `just`, because contributors expect it.

### 12d. TypeScript template should support both library and app modes

Your typescript-ui-kit is a component library; other TS projects might be apps. Consider a `--mode lib|app` flag for the TS template, or at minimum set up `tsconfig.json` with proper `composite` and `paths` configuration.

---

## 13. Missing from Phase 1: `CONTRIBUTING.md`

If you ever hand one of these repos to a collaborator or contractor, they need to know:

- How to set up locally
- How to run tests
- How to add a block vs. a lab
- Branch naming / PR conventions

This should be a baseline file in every generated repo.

---

## 14. Suggested Updated File Tree

Here's the plan's file tree with all additions marked:

```
micro-lab-template/
  README.md
  LICENSE
  AGENTS.md
  SESSION_LOG_TEMPLATE.md
  CONTRIBUTING.md                  ← NEW
  CHANGELOG.md                     ← NEW
  .editorconfig
  .gitattributes
  .gitignore
  .template-version                ← NEW (e.g., "0.1.0")

  docs/
    principles.md
    structure.md
    ci-and-security.md
    block-contract.md              ← NEW (defines what makes a block a block)

  scripts/
    new-repo.sh                    # add: --dry-run, --no-git, --docker flags
    selftest.sh
    setup-hooks.sh                 ← NEW (installs pre-commit hook)
    _lib.sh

  templates/
    _shared/                       ← NEW (files common to ALL languages)
      .env.example
      .dockerignore
      .gitignore
      SECURITY.md
      CONTRIBUTING.md
      README.md                    # with __PLACEHOLDERS__
      .github/
        CODEOWNERS
        pull_request_template.md
        dependabot.yml             # moved here — each generated repo gets its own
    rust/
      Cargo.toml                   # workspace-aware
      Dockerfile                   ← NEW
      justfile                     ← NEW (or scripts/dev.sh)
      crates/blocks/config/
      crates/blocks/logging/
      crates/blocks/errors/        ← NEW
      crates/lab_cli/
    go/
      Dockerfile                   ← NEW
      justfile                     ← NEW
      internal/blocks/config/
      internal/blocks/logging/
      internal/blocks/errors/      ← NEW
      cmd/lab-cli/
    python/
      pyproject.toml               ← NEW (replaces setup.py approach)
      Dockerfile                   ← NEW
      justfile                     ← NEW
      src/__PKG__/blocks/config.py
      src/__PKG__/blocks/logging.py
      src/__PKG__/blocks/errors.py ← NEW
      labs/01_cli.py
    ts/
      tsconfig.json
      Dockerfile                   ← NEW
      justfile                     ← NEW
      src/blocks/config.ts
      src/blocks/logging.ts
      src/blocks/errors.ts         ← NEW
      labs/01_cli.ts

  .github/
    workflows/
      ci-selftest.yml              # keep as-is
      ci-templates.yml             ← CHANGED (matrix strategy, replaces per-lang files)
      ci-generator.yml             ← NEW (tests generator itself)
    dependabot.yml                 # for the template repo itself
```

---

## 15. Recommended Implementation Order (Revised)

The original plan's phasing is fine, but insert these adjustments:

| Phase | Original | Add |
|-------|----------|-----|
| 0 | Create repo + clone | No change |
| 1 | Baseline files | Add: `CONTRIBUTING.md`, `CHANGELOG.md`, `.template-version`, `SECURITY.md` template, `docs/block-contract.md` |
| 1.5 | **NEW: Shared template layer** | Create `templates/_shared/` with files common to all languages |
| 2 | Language templates | Add: error block, config with env loading, `Dockerfile`, `justfile`, `pyproject.toml` for Python |
| 3 | Generator script | Add: `--dry-run`, `--no-git`, `--docker` flags, prerequisite checking, merge `_shared/` into output |
| 3.5 | **NEW: Generator self-test** | Script that generates a repo and verifies no leftover placeholders |
| 4 | CI workflows | Switch to matrix strategy, add generator test job, add Windows runner |
| 5 | Documentation | Add block contract docs, updated README with all new features |

---

## 16. What I'd Explicitly NOT Add Yet

To keep scope sane:

- **Monorepo tooling** (Nx, Turborepo) — you don't need it until you have 3+ packages in one repo
- **SBOM / SLSA provenance** — nice for enterprise, overkill for v1
- **Helm charts / K8s manifests** — Docker is enough for now
- **Language-specific package publishing** (crates.io, PyPI) — add when a block is mature enough to share
- **Remote development containers** (devcontainer.json) — useful but can be Phase 6
- **Template update/sync mechanism** — stamp the version now, build the upgrade tool later

---

## Summary of High-Impact Additions

If you only do five things from this review:

1. **Define the block contract** (`docs/block-contract.md`) — this is the thing that makes 60 blocks across 10 repos actually composable
2. **Add `templates/_shared/`** — stops you from duplicating `.env.example`, `SECURITY.md`, `README.md`, `CONTRIBUTING.md` across every language template
3. **Add the error handling block** to each template — config + logging without errors is an incomplete foundation
4. **Add `--dry-run` to the generator** — you will debug placeholder replacement; make it easy
5. **Switch CI to matrix strategy** — one workflow file instead of five, adding a language is one line

Everything else is gravy that compounds over time.
