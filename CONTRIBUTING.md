# Contributing to amonite

## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled (`experimental-features = nix-command flakes`)
- Git

## Development shell

Enter the development environment with all required tools:

```sh
nix develop
```

## Commit style

amonite uses **Conventional Commits** for all commit messages:

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

Examples:
- `feat(cli): add --flow-only flag to amonite init`
- `fix(lib): handle missing task directory gracefully`
- `docs(contributing): clarify conventional commit format`

## Branch naming

- `feat/<description>` — new feature
- `fix/<description>` — bug fix
- `docs/<description>` — documentation update
- `chore/<description>` — maintenance, deps, tooling

## Pull request process

1. Fork the repository and create a branch from `main`
2. Make your changes and ensure all checks pass: `nix flake check`
3. Open a pull request against `main`
4. CI must pass (nix flake check on ubuntu and macos)
5. A maintainer will review and merge

## Release procedure

Releases are automated via [release-please](https://github.com/googleapis/release-please).
Conventional commits merging to `main` accumulate in a release PR.
Merge the release PR to cut a new version — no manual `git tag` needed.

The release-please GitHub Actions workflow runs on every push to `main` and
maintains an open PR that bumps the version and updates CHANGELOG.md.
When you are ready to release, simply merge that PR.

## Code style

- **Bash**: all shell scripts must pass `shellcheck --shell=bash`
- **Nix**: format `.nix` files with `nixfmt-rfc-style`
- **Go**: standard `gofmt` formatting for TUI code
