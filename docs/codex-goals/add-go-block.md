# Add Go Block

```text
/goal Add a Go block to micro-lab-template without generator drift.

Inputs:
- Block name and behavior contract. If either is missing, ask before editing.

Read first:
- AGENTS.md
- docs/canonical.md
- docs/v2-roadmap.md
- docs/principles.md
- docs/block-contract.md
- docs/structure.md
- templates/go/internal/blocks

Deliver:
1. Add the Go block under templates/go/internal/blocks.
2. Provide a constructor or init path that accepts explicit configuration.
3. Add focused offline tests next to the block code.
4. Add block README coverage if the new block introduces usage or configuration that is not already documented.
5. Update generated usage docs only when the new block changes the generated repo contract.

Constraints:
- Keep the change Go-scoped unless docs or generator behavior must be updated for correctness.
- Prefer the Go standard library.
- Do not modify Rust templates for a Go-only block.
- Do not add Python or TypeScript templates.
- Keep blocks importable libraries; labs only compose and demonstrate them.

Validation:
- cd templates/go && gofmt -l .
- cd templates/go && go vet ./...
- cd templates/go && go test ./...
- bash scripts/selftest.sh go
- bash scripts/check-line-endings.sh
- If shellcheck is installed: cd scripts && shellcheck -x *.sh

Stop when:
- The new block follows docs/block-contract.md.
- Go checks pass.
- Generated-repo behavior remains aligned with docs.
- The diff is limited to the Go block, required tests, and directly related docs.
```
