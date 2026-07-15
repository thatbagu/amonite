# Contributing

## Prerequisites

- Nix with flakes enabled

## Dev shell

```bash
nix develop
```

This drops you into a shell with `amonite`, `git`, `jq`, `shellcheck`, `go`,
and `mdbook` available.

## Running checks

```bash
nix flake check
```

This builds and verifies the library self-tests, the TUI, and the CLI
shellcheck pass. All checks are hermetic.

## Commit style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add rollback --dry-run flag
fix: ensure flake.lock is committed before verify
docs: expand architecture layer descriptions
chore: bump nixpkgs to nixos-25.05
```

Types used in this project: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`.

## Pull requests

Target branch: `main`.

Before opening a PR:

- `nix flake check` must pass
- `.nix` files must pass `nixfmt-rfc-style` formatting
- `bin/amonite` must pass `shellcheck --shell=bash`

## Code style

| File type | Rule |
|---|---|
| `.nix` | `nixfmt-rfc-style` |
| Shell (`bin/amonite`) | `shellcheck --shell=bash` must pass |
| Go (`tui/`) | `go fmt` |
