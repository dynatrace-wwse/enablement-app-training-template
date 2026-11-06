# 11 — Shared Infrastructure: the Workshop Shell File

Some workshops cannot give every learner a personal environment — a GPU box for an AI agent, a large application estate, a fault scenario everyone hunts together. For those, a training ships **one shared machine for the whole room**, built by its own scripts:

| Script | Runs on | When |
|---|---|---|
| `.devcontainer/workshop-post-create.sh` | the **shared** machine | once, when the trainer's workshop starts |
| `.devcontainer/workshop-post-start.sh` | the shared machine | every start — and after the trainer presses **Refresh tokens** |
| `.devcontainer/post-create.sh` / `post-start.sh` | each **learner seat** (if seats are personal) | as for any hands-on training |

The presence of `workshop-post-create.sh` **is** the declaration of shared infrastructure — Orbital derives it, you never set a flag. And it binds the training: it must declare `workshop-only` **and** `same-tenant` (see [Kinds of Trainings](m1-kinds-of-trainings.md)), or Orbital refuses to start it in shared mode (`400 shared_needs_single_tenancy`).

!!! note "Why this training ships no workshop shell file"
    Shipping one would make this training workshop-only and single-tenant — and it is meant to run in every tenant, self-service. The scripts below are taken from real shared trainings: [test-internal-shared-workshop](https://github.com/dynatrace-wwse/test-internal-shared-workshop) and [Build Your Own Agent](https://github.com/dynatrace-wwse/enablement-build-your-own-agent).

## The shared machine's environment

Orbital runs the workshop scripts **instead of** `post-create.sh` / `post-start.sh` on the shared job, and sets two variables your scripts can read:

- `ORBITAL_SHARED_ROLE=shared`
- `ORBITAL_WORKSHOP_ID=ws_…`

The scripts are a fixed allowlist — Orbital never runs a path taken from a request.

## Shape of the scripts

```bash title=".devcontainer/workshop-post-create.sh"
#!/bin/bash
# Shared box, once. Idempotent: a re-run attaches to what exists.
export SECONDS=0
source .devcontainer/util/source_framework.sh
setUpTerminal
printInfo "ORBITAL_SHARED_ROLE=${ORBITAL_SHARED_ROLE:-unset} ORBITAL_WORKSHOP_ID=${ORBITAL_WORKSHOP_ID:-unset}"
buildSharedBox                       # your function in my_functions.sh: cluster, apps, Dynatrace
checkSharedBoxReady && printInfo "Shared box ready in ${SECONDS}s" || printError "Shared box NOT ready"
finalizePostCreation
```

```bash title=".devcontainer/workshop-post-start.sh"
#!/bin/bash
# Shared box, every start: bring the stopped cluster back.
source .devcontainer/util/source_framework.sh
# Tokens may have been refreshed since the last start: re-read .env so a NEW variable is exported too.
if [[ -f "${ENV_FILE:-}" ]]; then set -a; source "$ENV_FILE"; set +a; fi
dynatraceEvalReadSaveCredentials
buildSharedBox                       # idempotent — attaches to what exists
deployDynatrace                      # re-applies the DynaKube, whose secret carries the token
checkSharedBoxReady
```

Rules that keep a shared box healthy:

- **Idempotent, both scripts.** A restart and a token refresh run `workshop-post-start.sh` on a machine that already has everything.
- **Re-apply what carries a token.** After *Refresh tokens*, anything that read the old token (the DynaKube secret, an app's config) must be re-applied, or it keeps sending with a dead token.
- **The script's exit status is the readiness check's.** End with the check, so a failed refresh is recorded as failed.

## What the trainer controls

The trainer sees the shared machine in the app's **Shared Workspace** tab — build log, terminal, registered apps — and decides what learners see: **share terminal** and **share apps** are off by default. A learner without sharing gets nothing; with apps shared, they get app links only, never the IDE.

Learner seats beside a shared machine (`seats.personal: true`) are not built yet, so a shared training declares `seats.personal: false`.

<!-- LAB_QUESTION
type: multiple-choice
question: "The trainer presses Refresh tokens on a shared workshop. Which script runs, and what must it do?"
options:
  - "post-create.sh — rebuild everything from scratch"
  - "workshop-post-start.sh — re-read .env and re-apply whatever carries the token, idempotently"
  - "workshop-post-create.sh — it always runs again"
  - "No script runs; tokens update in place"
correct: 1
explanation: "A refresh runs workshop-post-start.sh on the existing machine. It re-reads the refreshed .env and re-applies token consumers such as the DynaKube."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "Which declaration does Orbital require from a training that ships workshop-post-create.sh?"
options:
  - "availability: self-service, tenancy any"
  - "availability: workshop-only and type: multi-tenant"
  - "availability: workshop-only and type: same-tenant"
  - "None — the script is enough"
correct: 2
explanation: "Shared infrastructure is derived from the script and must be workshop-only and single-tenant (same-tenant)."
-->

<!-- LAB_NO_SOLUTION: reading step with knowledge checks — this training ships no shared script on purpose -->
