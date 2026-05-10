# Add Rust Block

```text
/goal Add a Rust block to micro-lab-template without generator drift.

Inputs:
- Block name and behavior contract. If either is missing, ask before editing.

Read first:
- AGENTS.md
- docs/canonical.md
- docs/v2-roadmap.md
- docs/principles.md
- docs/block-contract.md
- docs/structure.md
- templates/rust/crates/blocks/README.md

Deliver:
1. Add the Rust block under templates/rust/crates/blocks/src.
2. Export it through templates/rust/crates/blocks/src/lib.rs.
3. Add focused offline tests.
4. Add or update block README coverage where the existing Rust template expects it.
5. Update generated usage docs only when the new block changes the generated repo contract.

Constraints:
- Keep the change Rust-scoped unless docs or generator behavior must be updated for correctness.
- Do not add dependencies unless the block cannot satisfy the contract without them.
- Do not modify Go templates for a Rust-only block.
- Do not add Python or TypeScript templates.
- Keep blocks importable libraries; labs only compose and demonstrate them.

Validation:
- cd templates/rust && cargo fmt --all -- --check
- cd templates/rust && cargo clippy -- -D warnings
- cd templates/rust && cargo test --workspace
- bash scripts/selftest.sh rust
- bash scripts/check-line-endings.sh
- If shellcheck is installed: cd scripts && shellcheck -x *.sh

Stop when:
- The new block follows docs/block-contract.md.
- Rust checks pass.
- Generated-repo behavior remains aligned with docs.
- The diff is limited to the Rust block, required exports/tests, and directly related docs.
```
