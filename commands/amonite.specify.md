---
description: Write the specification (what & why) from a project prompt
---

Create or update `.amonite/spec.md` from the user's project description.

**If spec.md already exists**, read it first — understand what stories are
already there, what's in scope and out. You are adding to or amending the
spec, not replacing it. Preserve existing story IDs (US1, US2…); new
stories continue the sequence.

1. Fill the spec template: intent, priority-ordered user stories, out of
   scope, open questions. NO tech stack, NO file paths — that is plan.md.
2. Each user story must be independently deliverable: it will become a
   cluster of task derivations. If a story can't stand alone, split or
   merge until it can.
3. Every "Done when" bullet must be OBSERVABLE and BEHAVIORAL — phrased so
   it can later compile into a `verify` entry that runs the built artifact,
   not one that merely checks files exist or contain strings.

   Verification quality hierarchy (best → acceptable):
   - **Run the artifact**: `"$out/bin/tool" subcommand` exits 0 with expected
     output. This is the default. If the story produces an executable, its
     verify must invoke it.
   - **Compile/lint**: `go build`, `shellcheck`, `bash -n`, `nix eval` — for
     build-time correctness that can't be tested by running.
   - **Structured parse**: `jq`, `yq` on config/YAML — to assert shape, not
     just string presence.
   - **Content grep**: last resort, only for invariants that truly can't be
     tested by executing (e.g. license header, comment in generated file).
   - **`test -f`**: only as a prerequisite guard, never as the primary
     criterion. "File exists" is not evidence of correctness.

   Reject "Done when: file X exists" or "Done when: X contains string Y"
   unless there is no runnable form. Push until you get: "Done when: running
   `tool subcommand` prints Z and exits 0."
4. **Resolve open questions NOW.** Before writing anything as an Open
   question, ask yourself: can the user answer this with a simple choice
   right now? If yes, ask them immediately using the question tool and bake
   the answer into the spec. Only leave something as an Open question if it
   genuinely requires external research, third-party decisions, or data you
   cannot obtain in this conversation (e.g. "what is the p99 latency of
   endpoint X in production?"). The Open questions section should be empty
   at the end of a normal specify run — `/amonite.plan` will refuse to
   proceed if it is not.
5. Check the result against `.amonite/principles.md`; flag conflicts.

User input: $ARGUMENTS
