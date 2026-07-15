# amonite Comparative Analysis: Spec-Driven and Hermetic-Build Frameworks

## Summary

amonite occupies a distinct niche: it is the only framework surveyed that
combines a structured, human-authored spec flow (principles → spec → plan →
tasks) with compile-time mechanical verification via the Nix build graph. Peer
frameworks solve adjacent problems — devenv standardises developer environments,
Dagger and Earthly make CI pipelines portable and container-isolated, and
flake-parts modularises Nix flakes — but none of them treats the spec as a
first-class input that compiles into acceptance criteria enforced at build time,
without any LLM re-reading markdown to decide compliance.

---

## Spec Format Comparison

| Framework     | Spec format                                     | Verification mechanism                                            | Hermeticity                                      |
|---------------|-------------------------------------------------|-------------------------------------------------------------------|--------------------------------------------------|
| **amonite**   | Markdown flow (`.amonite/*.md`) + `task.nix`    | Nix derivation build; every `verify` snippet must exit 0         | Full Nix sandbox; no network; pinned inputs      |
| **devenv**    | `devenv.nix` (Nix expression)                   | `devenv test` runs `enterTest` shell commands                     | Nix evaluation caching; not a full build sandbox |
| **Dagger**    | Go/Python/TypeScript/PHP/Java functions or REPL | Function execution in OCI containers; typed dependencies          | Container isolation; explicit host resource passing |
| **Earthly**   | `Earthfile` (Dockerfile-like DSL)               | Target execution in Docker containers; atomicity per build        | Docker isolation; "rest is completely isolated"  |
| **flake-parts** | Nix module system inside `flake.nix`          | `nix flake check` via `checks.*` derivations                     | Full Nix sandbox (inherits from Nix flakes)      |

amonite's spec format is unusual in that it spans two layers: human-readable
markdown (`.amonite/{principles,spec,plan,tasks}.md`) that embeds observable
"done when" criteria, which are then compiled into `verify` entries in
`task.nix`. As the architecture document states: "every 'done when' must be
observable (it will become a 'verify' entry)." The other frameworks have no
equivalent two-layer, spec-to-derivation pipeline.

devenv's `devenv.nix` defines environments rather than specifications; there
is no concept of "acceptance criteria" separate from environment configuration.
Dagger expresses workflows "as combinations of functions from the Dagger API,"
which is programmable but does not distinguish spec from implementation.
Earthly's Earthfile is similar to Dockerfiles but with enhanced capabilities,
oriented toward build recipes, not human-readable specifications.
flake-parts uses Nix's module system as its configuration language and
imposes no workflow stages or acceptance criteria.

---

## Where amonite Is Stronger

**Mechanical, non-LLM verification.** amonite's core design position is that
"spec frameworks got the flow right and verification wrong: 'does the code
satisfy the spec?' is answered by an LLM re-reading markdown. amonite keeps
the flow and replaces the answer with the Nix build graph." A derivation either
builds or it doesn't; the spec's verifiable core "compiles to derivations"
so an "agent inside a no-network sandbox with pinned inputs cannot talk its way
past that." No other framework surveyed offers this property.

**Structured spec flow with a project constitution.** The five-step flow
(principles → specify → plan → tasks → implement) enforces that every project
maintains a persistent `principles.md` constitution and that spec criteria are
observable before any implementation begins. Principle E1 states: "Every task's
acceptance criteria MUST be mechanical: expressible as 'verify' entries in its
task.nix. 'Looks correct' is not a criterion." Peer tools have no equivalent
upstream governance.

**Verification ladder with explicit impure boundary.** amonite's verification
ladder (`task.verify` → `cluster.verify` → `APP.verify` → `gate.live`) is
honest about what can and cannot be hermetic. "The ladder's honesty property:
everything below 'gate.live' is provably hermetic, so when something fails at
'gate.live' you know it's the world, not the toolchain." No other tool surveyed
makes this distinction explicit in the framework itself.

**AI-agent workflow built in.** The parallel-agent wave planner (US5) produces
`task-graph.json` with wave assignments so that "multiple agents [can be]
dispatched efficiently without coordination overhead." The `mkResearchTask`
function (US9) extends verification to AI-produced research: reports that fail
TF-IDF cosine similarity < 0.10 or NLI entailment score < 0.65 against their
source documents "fail the build just like broken code." This is a unique
capability among the frameworks surveyed.

**Minimal, frozen surface.** Principle N2 caps the lib surface at four
functions: `mkTask`, `mkCluster`, `mkApplication`, `mkResearchTask`.
"No further lib functions without an explicit spec amendment." This prevents
the kind of gradual feature sprawl that undermines tool longevity.

---

## Where amonite Lags

**Nix-only.** Principle P3 states: "The canonical install paths are nixpkgs
and nix flakes; no Python, no npm." This is a deliberate constraint, but it
limits adoption to the Nix ecosystem. Dagger supports eight languages and
requires a container runtime as its only dependency. Earthly similarly targets
any team using Docker. devenv offers "50+ supported languages" and
"100,000+ prebuilt packages."

**No built-in service orchestration.** devenv provides 30+ declarative services
("PostgreSQL, Redis, MySQL, RabbitMQ, Elasticsearch") that start and stop
automatically during `devenv test`. amonite's `mkVmVerify` wraps
`pkgs.testers.runNixOSTest` for VM-level integration tests, but this
"requires Linux builders; on darwin configure a linux-builder or remote builder."

**No remote execution or cloud backend.** Dagger provides "Dagger Cloud for
advanced capabilities" including browser-based tracing and debugging. Earthly
offers remote runners as a documented tutorial step. amonite is intentionally
local ("No orchestrator daemon, no state DB: the Nix store is the state") and
has no remote runner story.

**Ecosystem maturity.** Dagger is in production at Ubisoft, CERN OpenLab,
Grafana Labs, Adobe, NVIDIA, and Databricks. devenv uses the same release
model (release-please) as amonite but is considerably more established.
flake-parts is widely used across the Nix community. amonite is self-hosted
and pre-1.0, lacking a nixpkgs submission (noted as "separate PR after nixpkgs
submission" in the spec's out-of-scope list).

---

## Developer Workflow Comparison

**amonite:** The developer (or AI agent) follows a linear flow driven by
Claude Code slash commands: `/amonite.principles` → `/amonite.specify` →
`/amonite.plan` → `/amonite.tasks` → `/amonite.implement`. Verification is
`amonite verify T001 / C001 / APP / all`, which maps directly to
`nix build .#task-T001 / nix flake check`. Agents are assigned individual
task capsules (`tasks/TNNN/`) with "exactly the granted env" via `nix develop`,
so "capsule and aggregate can never disagree."

**devenv:** The developer runs `devenv init`, edits `devenv.nix`, and enters
the environment with `devenv shell`. Tests run via `devenv test`, which "builds
your developer environment and makes sure that all checks pass." There is no
spec-to-task pipeline; the workflow is environment-centric, not project-centric.

**Dagger:** Developers write pipeline functions in their language of choice, then
run them locally or in CI. "IDE Integration gives you automatic type-checking,
code completion." There is no spec or task decomposition layer; Dagger is a
pipeline engine, not a project governance tool.

**Earthly:** Developers write `Earthfile` targets and run `earthly +targetname`.
"A build either succeeds completely or it fails altogether, with outputs written
only upon success." Independent steps execute in parallel automatically. Like
Dagger, there is no upstream spec or task governance.

**flake-parts:** Developers split their `flake.nix` across modules using
Nix's module system. Verification is `nix flake check` via `checks.*`
derivations. flake-parts is a structural utility; it imposes no workflow and
has no agent or spec integration.

---

## Conclusion

amonite is the only framework among those surveyed that treats the software
specification as a first-class, compilable input: "The spec's verifiable core
compiles to derivations; a derivation either builds or it doesn't." Its
verification ladder is uniquely honest about the hermetic/impure boundary,
its spec flow enforces observable acceptance criteria before implementation
begins, and its `mkResearchTask` function extends that mechanical verification
to AI-produced research outputs.

Its weaknesses are structural: the Nix-only distribution model limits audience,
there is no remote execution backend, and the project is pre-1.0 without a
nixpkgs submission. Dagger and Earthly outperform it on portability and
ecosystem maturity; devenv outperforms it on service orchestration and
language coverage. The comparison is largely orthogonal, however — amonite
targets spec-driven project governance with hermetic verification of acceptance
criteria, a position none of the other frameworks occupies.
