# AGENTS.md

Generated repo guide for `__REPO_NAME__`.

## Context

- Generated from `micro-lab-template` v__TEMPLATE_VERSION__.
- Module path: `__MODULE_PATH__`.
- Blocks live in `__BLOCKS_DIR__/`.
- Labs live in `__LABS_DIR__/`.

## Operating Contract

- Keep blocks importable, tested libraries.
- Keep labs as runnable compositions of blocks.
- Do not put application entrypoints inside block packages.
- Do not make blocks depend on labs.
- Do not require network access, secrets, or external services for default tests.
- Keep generated CI and local checks aligned when behavior changes.

## Checks

Run the canonical test command before handoff:

```bash
__TEST_COMMAND__
```

Run the sample lab when changing runtime behavior:

```bash
__RUN_COMMAND__
```

## Block Rules

Every block must have:

1. Explicit initialization through configuration.
2. Structured logging instead of raw print statements.
3. Typed errors with useful context.
4. At least one offline test.
5. An importable library API.
6. A README with purpose, usage, configuration, and dependencies.

The upstream contract is documented at:

https://github.com/__ORG__/micro-lab-template/blob/main/docs/block-contract.md

## Change Discipline

- Prefer the current repo layout over new structure.
- Add tests with behavior changes.
- Keep docs concise and operational.
- Do not commit secrets, local paths, generated credentials, or tool caches.
