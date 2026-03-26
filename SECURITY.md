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
- Dependabot configuration for GitHub Actions, the generated language, and Docker base images
- CI with minimal workflow permissions (`contents: read`)
- Secret scanning with Gitleaks
- Vulnerability and Dockerfile scanning with Trivy
- Dependency auditing with `govulncheck` (Go) or `cargo audit` (Rust)
- Docker containers running as non-root
