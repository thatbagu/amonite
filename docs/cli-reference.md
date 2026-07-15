# CLI Reference

```shell
amonite — spec-driven development compiled to Nix derivations

Usage:
  amonite init [dir]            scaffold a project (meta flake + flow files)
  amonite task new <ID> <title> spawn an encapsulated task capsule
  amonite verify <ID>|APP|all   build+verify a task/cluster, APP, or everything
  amonite tui                   interactive derivation-hierarchy viewer
  amonite generations           list APP generations (NixOS-style)
  amonite rollback [N]          switch current APP to generation N (default: previous)
  amonite status                flow artifacts, checklist state, current generation
```
