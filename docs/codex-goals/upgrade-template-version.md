# Upgrade Template Version

```text
/goal Upgrade the micro-lab-template version coherently across template metadata, docs, and generated output.

Inputs:
- Target semantic version. If missing, inspect the requested change and ask for the target version before editing.

Read first:
- AGENTS.md
- docs/canonical.md
- docs/v2-roadmap.md
- docs/principles.md
- docs/structure.md
- CHANGELOG.md
- .template-version
- scripts/new-repo.sh

Deliver:
1. Update .template-version to the target version.
2. Add a concise CHANGELOG.md entry with user-visible template changes.
3. Update README.md and docs/canonical.md if commands, supported languages, generated files, or workflow expectations changed.
4. Verify generated dry-run output reports the target version.
5. Do not change generator behavior unless the version upgrade explicitly requires it.

Constraints:
- Do not add dependencies.
- Do not add Python or TypeScript templates.
- Keep version changes mechanical and reviewable.
- Keep generated repo compatibility notes concise and operational.

Validation:
- bash scripts/selftest.sh all
- bash scripts/check-line-endings.sh
- bash scripts/new-repo.sh --lang rust --name version-smoke-rust --no-git --dry-run
- bash scripts/new-repo.sh --lang go --name version-smoke-go --no-git --dry-run
- If shellcheck is installed: cd scripts && shellcheck -x *.sh

Stop when:
- Version metadata and docs agree.
- Dry-run output shows the target version for both supported languages.
- Canonical checks pass.
- The diff is limited to version metadata, changelog, directly related docs, and any explicitly required generator/template updates.
```
