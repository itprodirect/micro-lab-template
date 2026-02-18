# Contributing to __REPO_NAME__

## Setup

```bash
git clone https://github.com/__ORG__/__REPO_NAME__.git
cd __REPO_NAME__
```

## Running Tests

```bash
__TEST_COMMAND__
```

## Running the Lab

```bash
__RUN_COMMAND__
```

## Project Structure

- `__BLOCKS_DIR__/` — Reusable library modules (blocks)
- `__LABS_DIR__/` — Applications that compose blocks

## Adding a New Block

1. Create a new module in `__BLOCKS_DIR__/`
2. Follow the [block contract](https://github.com/__ORG__/micro-lab-template/blob/main/docs/block-contract.md)
3. Ensure it has typed errors, structured logging, and at least one test
4. Use it in an existing or new lab

## Commit Conventions

Use conventional commits: `feat(scope): message`, `fix(scope): message`, `docs: message`
