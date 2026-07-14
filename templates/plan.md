# Implementation Plan: [PROJECT / FEATURE NAME]

**Spec**: [link to spec.md] · **Principles check**: [pass/violations]

## Technical context

- **Language/runtime**: [e.g. Python 3.12]
- **Key dependencies**: [frameworks, libraries]
- **Storage**: [if any]
- **Target**: [where this runs]

## Meta environment (compiles into project flake devShell)

<!-- /amonite.plan applies this list to the `# amonite:toolchain` marker
     in the project flake.nix. Keep minimal: task-specific tools belong
     in task envs, not here. -->

- pkgs.[package]
- pkgs.[package]

## Architecture

[Component diagram / prose. Name the parts; tasks will map onto them.]

## Verification strategy

<!-- The heart of the plan. For each layer, how correctness is checked
     mechanically. Anything unverifiable hermetically goes to gate.live. -->

| Layer | How verified | Hermetic? |
|-------|--------------|-----------|
| unit  | [e.g. pytest per task, inside task derivation] | yes |
| integration | [e.g. cluster verify: services in nixosTest] | yes |
| gate.live | [impure checks needing the real world, run manually] | NO |

## Cluster topology (planned)

<!-- The shape tasks will roll up into. Refined by /amonite.tasks. -->

- C001 foundation ← [T...]
- C002 [US1 name] ← [T...]
- APP ← C001, C002, ...

## Risks / complexity

| Risk | Mitigation |
|------|------------|
| | |
