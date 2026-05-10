# Investigate Failing Selftest

```text
/goal Investigate and fix a failing micro-lab-template selftest without masking the failure.

Inputs:
- Failing command or error output if available. If missing, reproduce with the canonical check.

Read first:
- AGENTS.md
- docs/canonical.md
- docs/v2-roadmap.md
- docs/principles.md
- docs/block-contract.md
- docs/structure.md
- scripts/selftest.sh
- scripts/new-repo.sh
- scripts/check-line-endings.sh

Procedure:
1. Reproduce the failure with bash scripts/selftest.sh all unless the user supplied a narrower failing command.
2. Isolate whether the failure is manifest validation, Rust template, Go template, generator smoke, line endings, or environment/toolchain.
3. Inspect the smallest relevant code and docs surface.
4. Fix the root cause; do not weaken checks to make them pass.
5. If the failure is environmental, document the missing tool or unavailable runtime and run every unaffected check.

Constraints:
- Do not add dependencies unless the missing dependency is already part of documented tooling.
- Do not add Python or TypeScript templates.
- Do not refactor generator behavior unless the failure is caused by generator behavior.
- Keep fixes scoped to the failing area and directly related docs.

Validation:
- bash scripts/selftest.sh all
- bash scripts/check-line-endings.sh
- bash scripts/new-repo.sh --lang go --name codex-smoke --no-git --dry-run
- If shellcheck is installed: cd scripts && shellcheck -x *.sh

Stop when:
- The failing check is explained.
- The root cause is fixed or clearly identified as an environment blocker.
- All runnable validation passes.
- The diff is limited to the failing area and directly related docs.
```
