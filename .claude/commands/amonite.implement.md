---
description: Implement tasks inside their capsules until clusters and APP verify
---

Work through `.amonite/tasks.md` in dependency order.

For each pending task TNNN:

1. Enter its capsule: `nix develop ./tasks/TNNN` — you get exactly the
   granted env. If a tool is missing, that is a PLAN problem: stop,
   record the needed grant in tasks.md, add it to task.nix env, continue.
   Never work around a missing grant with ambient tools.
2. Implement the task's `build` (and source files it needs). Do NOT touch
   its `verify` criteria to make them pass — criteria changes require the
   user (they are the spec's compiled form).
3. Verify: `amonite verify TNNN`. Building is verifying — iterate until
   the derivation exists. Then tick the checkbox in tasks.md.
4. When all tasks of a cluster are done: `amonite verify CNNN` — the
   cluster builds its members plus integration checks. Fix integration
   failures by fixing tasks, not by loosening cluster verify.
5. When all clusters verify: `amonite verify APP`. If it builds, the
   final derivation is the working application. Report the store path
   and remind the user of any gate.live items — those are theirs.

Parallelism: tasks marked [P] with satisfied dependencies may be
implemented by parallel agents, one capsule each; capsule isolation is
what makes that safe.

User input: $ARGUMENTS
