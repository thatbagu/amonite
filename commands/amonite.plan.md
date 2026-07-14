---
description: Produce the implementation plan and adjust the project meta flake
---

Create or update `.amonite/plan.md` from `.amonite/spec.md`, then apply the
meta-environment section to the project `flake.nix`.

Gate: if spec.md has unresolved Open questions, STOP and surface them.

1. Fix the technical context: language, dependencies, storage, target.
2. Design the architecture; name components — tasks will map onto them.
3. Write the verification strategy table. For every layer decide: hermetic
   (unit in task derivations, integration in cluster verify / nixosTest)
   or gate.live (impure, manual). Anything you cannot verify hermetically
   MUST appear in gate.live — hiding impurity violates principle E2.
4. Sketch the cluster topology: which clusters exist, roughly which tasks
   feed them, APP at the top.
5. Apply the "Meta environment" package list to the project flake.nix at
   the `# amonite:toolchain` marker. Keep it minimal (principle E3):
   project-wide tools only; task-specific tools go into task envs later.
6. Run `nix flake check` on the project root; the flake must still
   evaluate. Fix if broken.
7. Re-check the whole plan against `.amonite/principles.md`.

User input: $ARGUMENTS
