---
description: Implement tasks inside their capsules until clusters and APP verify
---

Work through `.amonite/tasks.md` in wave order. Run `amonite waves` first
to see the current verified/pending state across all waves.

**Wave-based parallel dispatch**

Before starting, run `amonite waves`. All tasks in the current wave that
show ○ (pending) may be assigned to parallel agents simultaneously — one
agent per capsule. Do not start a later-wave task until every task it
`depends` on shows ●.

To spawn an agent on a task:
  `nix develop ./tasks/TNNN`   — opens the capsule dev shell with exactly
                                  the granted env. The agent works here.

**Per-task loop** (for each assigned task TNNN):

1. Enter its capsule: `nix develop ./tasks/TNNN`. If a tool is missing,
   that is a PLAN problem: stop, record the needed grant in tasks.md,
   add it to task.nix env, continue. Never use ambient tools as a workaround.
2. Implement the task's `build` (and source files it needs). Do NOT touch
   `verify` criteria to make them pass — criteria changes require the user
   (they are the spec's compiled form).
3. Verify: `amonite verify TNNN`. Building is verifying — iterate until
   the derivation exists in the store. Then tick the checkbox in tasks.md.

**After each wave completes** (all tasks in the wave are ●):

4. Verify the cluster: `amonite verify CNNN`. Fix integration failures in
   the tasks, not by loosening cluster verify criteria.
5. Run `amonite waves` again — the next wave's tasks are now unblocked.

**When all clusters verify:**

6. `amonite verify APP`. The store path is the working application.
   Report it and surface any gate.live items — those belong to the user.

User input: $ARGUMENTS
