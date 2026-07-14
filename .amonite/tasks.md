# Tasks: [PROJECT / FEATURE NAME]

**Plan**: [link to plan.md]

<!-- Each task row corresponds 1:1 to tasks/TXXX/task.nix. A task is DONE
     when its derivation builds: `amonite verify TXXX`. Checkboxes here are
     a human-readable mirror; the store is the truth. -->

Format: `[ID] [P?] [Cluster] Title — env grants`

- `[P]` = parallelizable (no dependency on unfinished tasks)
- `[Cluster]` = which cluster this task rolls up into

## C001: Foundation

- [ ] T001 [P] [C001] [Title] — env: [pkgs...]
      verify: [named criteria, become task.nix `verify` entries]
- [ ] T002 [C001] [Title] — env: [pkgs...] (depends: T001)
      verify: [...]

## C002: [User Story 1]

- [ ] T010 [P] [C002] [Title] — env: [...]
      verify: [...]

## Cluster verifications

<!-- Integration criteria per cluster; become clusters.nix `verify`. -->

- C001: [e.g. "combined schema loads into empty db"]
- C002: [e.g. "end-to-end journey X passes in nixosTest"]
- APP: [final smoke — the working-application criterion]

## gate.live (impure, manual)

- [ ] [checks that need the real world, run by a human after APP builds]
