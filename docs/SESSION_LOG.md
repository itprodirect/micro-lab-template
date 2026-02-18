# Session Log

> A running record of decisions, friction, and learnings. Agents and humans both write here. Newest entries at the top.

---

## Session 001 — Planning & Doc Prep

**Date:** 2025-02-17
**Participants:** Nick (human), Claude Opus (planning), ChatGPT (planning)
**Tools:** Claude.ai, ChatGPT
**Next tools:** Claude Code + Codex (implementation)

### Goal

Prepare the complete documentation pack for `micro-lab-template` so Claude Code can execute implementation without ambiguity.

### Decisions made

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Block contract is the anchor document.** Every block in every repo follows the same 6 rules regardless of language. | Without a contract, 60 blocks across 10 repos diverge into incompatible patterns. The contract is what makes "LEGO blocks" actually composable. |
| 2 | **Rust + Go templates first, then Python + TS.** | Rust and Go are the two languages where the template's value is highest (more boilerplate to scaffold). Python and TS are faster to set up manually, so they're lower priority for the generator. |
| 3 | **Shared template layer (`templates/_shared/`) for cross-language files.** | Prevents duplicating `.env.example`, `SECURITY.md`, `CONTRIBUTING.md`, etc. across 4+ language directories. Generator copies shared first, then overlays language-specific. |
| 4 | **`just` (justfile) as task runner, not Make.** | `just` works on Windows without MSYS/MinGW, is a single binary with no deps, and has simpler syntax than Make. Fallback: if `just` isn't available, the justfile documents the raw commands. |
| 5 | **Error handling block is mandatory in every template.** Config + logging without errors is incomplete. | A lab that composes blocks needs typed errors to know what failed, where, and why. Untyped panics/exceptions break the composability promise. |
| 6 | **Generator gets `--dry-run` flag from v1.** | Placeholder replacement debugging is inevitable, especially on Windows. `--dry-run` lets you inspect output without creating files. |
| 7 | **CI uses matrix strategy, not per-language workflows.** | One file instead of four. Adding a language is one line in the matrix. Easier to maintain. |
| 8 | **All scripts are bash only.** No Python, Node, or compiled generators. | Bash is the lowest common denominator across Git Bash, CI, and any Linux. Adding a Python dependency to the generator creates a bootstrap problem. |
| 9 | **Deferred: SBOM, SLSA, Helm, devcontainers, package publishing.** | All valuable, all overkill for v1. Stamping `.template-version` now enables upgrade tooling later. |
| 10 | **Using ChatGPT + Claude for planning, Claude Code + Codex for implementation.** | Planning benefits from longer-context reasoning. Implementation benefits from tool use and file creation. Using both tools for their strengths. |

### Friction / open questions

| Issue | Status | Notes |
|-------|--------|-------|
| Git Bash `sed -i` behavior differs from GNU/macOS | Open | Generator placeholder replacement needs portable sed patterns. Test on both. |
| Go module path requires org+name before the repo exists | Open | Generator should use `github.com/__ORG__/__REPO_NAME__` as placeholder in `go.mod` — replaced at generation time. |
| Python package naming (kebab vs underscore) | Resolved | Repo name is kebab-case (`my-python-repo`), Python package is underscored (`my_python_repo`). Generator handles conversion via `__PKG__` placeholder. |
| Whether to pin Rust nightly vs stable | Resolved | Stable. Templates use `rust-toolchain.toml` pinning stable. Nightly features are not needed for config/logging/error blocks. |

### Docs produced this session

- `docs/block-contract.md` — block contract (6 mandatory rules + 4 recommendations)
- `docs/structure.md` — folder conventions + placeholder reference
- `docs/ci-and-security.md` — CI architecture + security defaults
- `docs/principles.md` — 10 design principles
- `docs/claude-review.md` — full gap analysis from Claude
- `TASKS.md` — ordered implementation checklist (10 phases)
- `AGENTS.md` — rules for AI agents working in this repo
- `SESSION_LOG.md` — this file

### Next session

Hand docs to Claude Code. Execute `TASKS.md` starting at Phase 1 (baseline files). Target: Phase 4 (Go template complete) by end of session.

---

<!-- Template for new entries:

## Session NNN — Title

**Date:** YYYY-MM-DD
**Participants:**
**Tools:**

### Goal

### Decisions made

| # | Decision | Rationale |
|---|----------|-----------|

### Friction / open questions

| Issue | Status | Notes |
|-------|--------|-------|

### What was built

### Next session

-->
