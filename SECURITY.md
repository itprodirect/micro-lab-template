# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this template repository or in a repo generated from it, please report it responsibly.

**Do NOT open a public issue for security vulnerabilities.**

Instead:
- Open a [private security advisory](https://github.com/itprodirect/micro-lab-template/security/advisories/new) on this repository
- Or email the maintainers directly

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Security Defaults

Every repo generated from this template includes:
- `.gitignore` patterns that prevent committing secrets
- `.env.example` (not `.env`) checked into version control
- Dependabot configuration for dependency updates
- CI with minimal permissions (`contents: read`)
- Docker containers running as non-root
