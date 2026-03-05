# V2 Roadmap

> Practical roadmap for evolving `micro-lab-template` with better correctness, CI signal, and maintainability.

## Outcomes

1. One source of truth for language behavior (generator, selftest, docs, CI).
2. CI for this repo and generated repos stays aligned by design.
3. Cross-OS hygiene is enforced automatically, not by convention.
4. Dependency update flow is low-friction and safe.

## Non-goals

1. No template rewrites.
2. No new frameworks/tooling stacks.
3. No broad repo restructuring unless tied to one roadmap item.

## Phase 1: Quick Wins (1-2 weeks)

### Scope

1. Canonicalize contributor and CI guidance.
2. Add lightweight guardrails for portability and text hygiene.
3. Reduce manual work for safe dependency bumps.

### Work Items

1. Add `docs/canonical.md` as a short index for current truth:
   - `bash scripts/selftest.sh all`
   - current CI workflow path
   - default branch policy
2. Add CI checks for shell and line ending hygiene:
   - `shellcheck` for `scripts/*.sh`
   - fail on CRLF in bash/yaml/md (allow Windows script extensions)
3. Add safe automerge policy for Dependabot GitHub Actions updates:
   - only for specific update scope
   - only when required checks are green
4. Add branch policy note in docs and keep workflows/docs consistent with it.

### Done Criteria

1. New PRs have one obvious place to verify current workflow conventions.
2. Portability regressions fail in CI before merge.
3. Dependabot Actions PRs no longer require manual babysitting when checks are green.

## Phase 2: Manifest-Driven Core (2-4 weeks)

### Scope

1. Introduce one language manifest used by generator + selftest + docs snippets.
2. Keep generated repo CI as a first-class tested output.

### Work Items

1. Create `config/languages.json` (or `.yaml`) with per-language:
   - IDs and paths
   - format/lint/test commands
   - run command
   - required toolchain checks
2. Refactor `scripts/selftest.sh` to read the manifest (or generate bash-compatible data from it).
3. Refactor `scripts/new-repo.sh` placeholder command population from the same manifest.
4. Add a small validation script that checks:
   - every manifest language has required keys
   - every referenced template path exists
5. Define generated-repo CI template(s) under `templates/_shared/.github/workflows/` and test through generator smoke tests.

### Done Criteria

1. Language command changes are made once in the manifest.
2. `new-repo.sh`, `selftest.sh`, and docs no longer drift on language commands.
3. Generated repo CI is versioned/tested as part of this template repo.

## Phase 3: Hardening + Future-Proofing (4-8 weeks)

### Scope

1. Strengthen release and upgrade ergonomics.
2. Prepare for adding new languages without multiplying complexity.

### Work Items

1. Add template release process:
   - version bump rules
   - changelog policy
   - release checklist
2. Add compatibility test matrix policy:
   - minimum supported Rust/Go versions
   - Windows/Linux parity expectations
3. Add upgrade guidance for generated repos:
   - what changes are safe to cherry-pick
   - where manual intervention is expected
4. Optional: add nightly CI job for early warning checks (non-blocking).

### Done Criteria

1. Template upgrades are predictable and documented.
2. New language onboarding follows a known checklist and does not fork architecture.
3. CI signal quality remains high as scope grows.

## Execution Order

1. Phase 1 first (high ROI, minimal risk).
2. Start Phase 2 with manifest + validation before touching generator/selftest logic.
3. Phase 3 only after Phase 2 is stable for at least one release cycle.

## Suggested First 3 Tickets

1. `docs: add canonical workflow index and branch policy note`
2. `ci: add shellcheck and line-ending guard`
3. `chore(ci): enable safe Dependabot automerge for GitHub Actions updates`