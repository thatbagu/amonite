---
description: Write the specification (what & why) from a project prompt
---

Create or update `.amonite/spec.md` from the user's project description.

1. Fill the spec template: intent, priority-ordered user stories, out of
   scope, open questions. NO tech stack, NO file paths — that is plan.md.
2. Each user story must be independently deliverable: it will become a
   cluster of task derivations. If a story can't stand alone, split or
   merge until it can.
3. Every "Done when" bullet must be OBSERVABLE — phrased so it can later
   compile into a mechanical `verify` entry. Reject vibes ("works well",
   "is fast") — ask for the observable version ("p95 < 200ms on dataset X").
4. Mark everything genuinely unknown as an Open question. Do not guess.
   If open questions remain, say so — /amonite.plan will refuse to run.
5. Check the result against `.amonite/principles.md`; flag conflicts.

User input: $ARGUMENTS
