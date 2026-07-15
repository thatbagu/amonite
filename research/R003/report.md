# Amonite Repository Self-Audit

**Task:** R003  
**Scope:** v0.2 sprint — spec compliance, verify quality, principle adherence, gap analysis  
**Sources:** spec.md, principles.md, tasks.md, lib.nix, verify-criteria.txt, implement-cmd.txt

---

## 1. Spec Compliance

The amonite v0.2 spec defines nine user stories (US1–US9). All nine are implemented as derivations in the tasks directory, with task.nix files providing hermetic build and verify blocks.

**US1 (flow-only init):** Implemented in T001. Verify criteria run `amonite init --flow-only` in a sandboxed git repository and confirm `.amonite/` is created without modifying `flake.nix`. These are behavioral checks consistent with E1.

**US2 (nixpkgs package):** Implemented in T003. A `package.nix` exists following nixpkgs conventions with `meta.description`, `meta.license`, `meta.mainProgram`, and `meta.maintainers`. The help-output verify criterion invokes `bash "$src/bin/amonite" --help` and checks for subcommand strings.

**US3 (shell completions):** Implemented in T004 with completions for bash, zsh, and fish installed under `$out/share/`. Syntax is verified by `bash -n`, `zsh --no-exec`, and `fish --command source` respectively, which are behavioral runtime checks.

**US4 (CLI UX hardening):** Implemented in T002. Verify criteria invoke the amonite binary and assert exit codes and stderr content, not just file existence.

**US5 (parallel-agent wave planner):** Implemented in T005. The `amonite waves` subcommand reads `task-graph.json` and prints wave headers; verify criterion invokes the binary and asserts output.

**US6 (mdBook documentation site):** Implemented in T006 and T007. The docs build runs `mdbook build docs` inside the derivation sandbox. The GitHub Pages workflow is verified by `test -f` on the workflow file and grep for `deploy-pages`.

**US7 (CI gate and release pipeline):** Implemented in T008, T009, T010. The CI workflow is verified to contain `macos-latest`, `cachix`, and `nix flake check`. Release-please config is confirmed by file existence and grep.

**US8 (TUI wave view):** Implemented in T011. The TUI builds via `nix build .#amonite-tui` and the wave key binding is verified by `nix build .#amonite-tui` exiting 0.

**US9 (research task type):** Partially compliant. `mkResearchTask` is callable and `nix flake check` exits 0 with it present. The `research-fixture` passes both gates. The `research-fixture-bad` fails TF-IDF (the fabricated sentence has zero lexical overlap with sources), satisfying the "fabricated claim fails" requirement. However, the NLI threshold in production tasks is calibrated at 0.35, below the 0.65 specified in US9, creating a spec drift that should be documented.

---

## 2. Verify Quality Assessment

The spec principle E1 states: "Every task's acceptance criteria MUST be mechanical: expressible as verify entries in its task.nix. 'Looks correct' is not a criterion." The implement command guidance further requires that verify blocks invoke executables rather than only checking file existence with `test -f` or `grep -q` on source files.

**C001 (cli-hardening):** Verify quality is high. T001 and T002 run the amonite binary in a tmp git sandbox and assert exact exit codes and stderr content. T005 invokes `amonite waves` and checks its output. These are behavioral assertions.

**C002 (distribution):** Mixed quality. T004 completions use `bash -n`, `zsh --no-exec`, and `fish --command source` — behavioral. T003 package.nix uses `grep -q` on source file content for most checks, with one behavioral invocation of `amonite --help`. The grep checks are justified because the Nix structure cannot be parsed without the Nix daemon in the sandbox; structural grep is the hermetic alternative.

**C003 (docs-site):** T006 and T007 use a mix of `test -f` and `grep -q` on workflow YAML files. These are weaker than behavioral criteria. The mdbook build invocation in T006 is behavioral but the workflow file checks are file-existence and content checks.

**C004 (release-pipeline):** T008, T009, T010 verify workflow YAML presence and content via `test -f` and `grep -q`. These are weak criteria per the implement command guidance: "A verify block that exercises no code is a false safety net." The workflows cannot be run hermeticallay (they require GitHub Actions), so `test -f` is the only hermetic option — these should be noted as E2 gate.live items rather than hermetic criteria.

**C006 (research-verify):** T012–T014 use grep-based verify criteria (checking that `mkResearchTask` appears in `nix/lib.nix`, that `verify_tfidf.py` exists, that `alignscore.nix` contains `outputHash`). T015 uses `nix build .#research-fixture` which is behavioral. T012–T014 criteria are below the standard set by the implement command guidance and should be upgraded.

---

## 3. Principle Adherence

**P1 (minimal surface):** The lib surface in `nix/lib.nix` exports seven symbols in the `rec` block: `mkTask`, `mkCluster`, `mkApplication`, `mkResearchTask`, `mkVmVerify`, `mkGraph`, and `loadTasks`. Principle N2 states: "The lib surface stays at four functions: mkTask, mkCluster, mkApplication, mkResearchTask. No further lib functions without an explicit spec amendment." The presence of `mkVmVerify` as a fifth user-facing specialization function is a potential N2 violation. `mkGraph` and `loadTasks` are infrastructure helpers, not research/task specializations, but `mkVmVerify` follows the same pattern as `mkResearchTask` — it is a specialization of mkTask without a spec amendment.

**P2 (self-applicable):** The `flake.nix` checks block includes `lib-task`, `lib-cluster`, and `research-lib` derivations that dogfood `mkTask`, `mkCluster`, and `mkResearchTask`. The `cli` check runs `shellcheck` on `bin/amonite`. These ensure `nix flake check` validates the framework against itself. R001 and R002 are live dogfood examples of mkResearchTask applied to amonite's own research questions.

**P3 (distribution follows the user):** The package.nix follows nixpkgs conventions. The flake exposes `packages.default`, `apps.default`, and `devShells.default`. No Python, npm, or non-Nix install paths are required.

**E1 (mechanical criteria):** Satisfied in C001 and partially in C002; weak in C003, C004, and C006 as noted above. The implement command guidance added an audit step ("Audit verify quality before dispatching") but this was added after C003/C004 tasks were already implemented.

**E2 (impure boundary explicit):** The `tasks.md` gate.live section lists six manual verification items: nixpkgs profile install, tab completion in interactive shell, flow-only on a third-party project, GitHub Actions CI run, docs site reachability, and GitHub Release creation. These are correctly declared as impure rather than embedded in weak verify blocks.

**E3 (minimal env):** Task envs are specific. C001 tasks grant `pkgs.bash pkgs.git pkgs.shellcheck`. Research tasks grant `pkgs.coreutils` plus a Python env with only the needed packages. The wave planner task adds `pkgs.jq` only where needed. No task grants a wide runtime.

**E4 (no new language runtimes):** The CLI is bash and Go. The Nix lib is pure Nix. The only runtime additions are Python (for verify scripts inside research task builds), which stays inside the research derivation and is not part of the CLI or library runtime.

**N1 (nix flake check green):** The `nix flake check` evaluates correctly. All implemented tasks and clusters build.

**N2 (four lib functions):** Potential violation via `mkVmVerify` as discussed under P1.

**N3 (shellcheck):** Every task in C001 includes `shellcheck-clean` as its first verify criterion, and the `cli` check in `flake.nix` runs shellcheck on `bin/amonite`. Principle satisfied.

---

## 4. Gap Analysis

**Gap 1 — NLI threshold spec drift:** US9 specifies an NLI threshold of 0.65; all three production research tasks (R001, R002, and the research-lib dogfood) use 0.35. The gap arises because AlignScore NLI-SP scores for well-grounded synthesis (not extraction) average around 0.43, making 0.65 unachievable. The spec should be amended to lower the default to 0.35 or document threshold calibration guidance by task type.

**Gap 2 — mkVmVerify N2 status:** `mkVmVerify` is present in `nix/lib.nix` but not named in N2's list of four functions and has no spec amendment authorizing it. Either remove it or add a spec amendment (N2 amendment) acknowledging it as an infrastructure helper distinct from task specializations.

**Gap 3 — C006 verify weakness:** T012–T014 verify criteria are grep-based file content checks. Per the implement command guidance ("a verify block that exercises no code is a false safety net"), these should be upgraded. For T012: run a test mkResearchTask and verify it builds. For T013: use the existing `research-fixture` check in `nix flake check`. For T014: run `nix build .#alignscore-weights` in the verify block.

**Gap 4 — research-fixture-bad and NLI:** The `research-fixture-bad` derivation fails TF-IDF (score near zero for quantum-physics sentence vs amonite source). The spec (US9) says the fabricated claim should specifically "fail the NLI gate." The current implementation fails the TF-IDF gate first, which satisfies the spirit but not the letter of US9. A proper bad fixture would pass TF-IDF (lexically similar to sources) but fail NLI (semantically divergent), testing the second tier independently.

**Gap 5 — gate.live undone:** Six gate.live items remain unvalidated. None block the sprint close, but they represent real risk: the nixpkgs PR has not been submitted, the docs site has not been reached at the github.io URL, and the release pipeline has not produced a real GitHub Release.

---

## 5. Recommendations

1. Amend the spec to set the default NLI threshold at 0.35 and add a note that synthesis tasks may require lower thresholds than extraction tasks.
2. Resolve the N2 status of `mkVmVerify`: add a spec amendment or move it out of the `rec` block into a private binding.
3. Upgrade T012–T014 verify criteria to behavioral checks as specified by the implement command guidance.
4. Add a second bad-fixture variant that passes TF-IDF but fails NLI, to test each tier independently.
5. Track gate.live items as a separate milestone rather than leaving them in the same tasks.md file, to avoid conflation with hermetic verifications.
