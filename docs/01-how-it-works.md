# 01 — How It Works

Three pieces work together: **your repo** (the content and the automation), the **Dynatrace Enablement app** (in the learner's tenant — the UI, the checks, the token minting) and **Orbital** (the server that runs one container per learner). This page follows a training from import to the last check.

---

## 1. Import — the app reads your repo, not a website

When a training is imported (**Import Lab**, or automatically for the dynatrace-wwse catalog), the app reads the **raw Markdown from the GitHub repo** — not the rendered GitHub Pages site:

| It reads | For |
|---|---|
| `mkdocs.yaml` (`nav:`) | The steps, in `nav` order. If every top-level `nav` entry is a section, one repo becomes **several trainings**. |
| `docs/<page>.md` | Each step's content and its interactive blocks (`LAB_QUESTION`, `LAB_SOLUTION`, `STEP_SETUP`, …). |
| Front-matter of the **first** page | Catalog card: `description`, `tags`, `difficulty`, `duration`. |
| `.assessment/<id>.json` | Scored assessments referenced by `LAB_QUESTIONAIRE`. |
| `.devcontainer/devcontainer.json` — does it exist? | **Hands-on** (a live environment) if it does, **self-paced** (docs + quizzes, no environment) if not. There is nothing to declare. |

GitHub Pages is still worth publishing — it is the readable, RUM-tracked site for people outside the app — but **the app does not depend on it**. A change reaches the app when it is on the repo's `main` branch and the training is imported again.

!!! note "Interactive blocks are HTML comments"
    `LAB_QUESTION`, `LAB_SOLUTION` and the other blocks are HTML comments: invisible on GitHub and in MkDocs. They only become buttons, quizzes and solution panels inside the app.

## 2. Start — tokens first, then the container

When a learner clicks **Start** on a hands-on training:

1. **The app mints tokens in the learner's tenant.** It asks Orbital which tokens this training needs — read from the repo's [`.devcontainer/yaml/dt-tokens.yaml`](02-automation.md#tokens-dt-tokensyaml), falling back to the framework default — and mints exactly those, scoped and valid for 4 hours. Nobody pastes a token.
2. **Orbital starts a container** from the framework image (`shinojosa/dt-enablement`) under **Sysbox**, so Docker and a k3d cluster run inside it unprivileged.
3. **Orbital writes `.devcontainer/.env`** before anything runs:

    | Variable | Value |
    |---|---|
    | `DT_ENVIRONMENT` | the learner's tenant URL |
    | `DT_OPERATOR_TOKEN`, `DT_INGEST_TOKEN` | minted tokens (the default `dt-tokens.yaml`) |
    | *any other `env_var`* | every extra token your `dt-tokens.yaml` declares, plus its `aliases` |
    | `DT_HOSTGROUP` | the learner's **session id**, `<user>-<yyyymmdd>` — the key to [per-learner isolation](04-interactive-blocks.md#template-variables-one-query-every-learner-isolated) |
    | `ORBITAL_ENVIRONMENT=true`, `ORBITAL_JOB_ID` | lets your functions know they run on Orbital |
    | `K3D_*`, `EXTERNAL_HOSTNAME` | cluster ports and the host name apps are exposed on |

4. **Orbital runs `.devcontainer/post-create.sh`, then `.devcontainer/post-start.sh`** — exactly as a Codespace would. This is where your cluster, Dynatrace and your apps get built. See [02 — Automate the Environment](02-automation.md).
5. The learner gets the steps next to a **terminal** into that container, with every framework function and your `my_functions.sh` already loaded.

## 3. Learn — every step is checked

| Block | Where it runs | What it proves |
|---|---|---|
| `shell-verification` | **in the learner's container** (Orbital) | the cluster/app is in the state the step asked for |
| `dql-verification` | **in the learner's tenant** (the app runs the DQL) | the telemetry really reached Grail |
| `multiple-choice`, `LAB_QUESTIONAIRE` | in the app | the learner understood the concept |
| `STEP_SETUP` | in the container, silently, when the step opens | prepares the step (e.g. generates the DynaKube) |
| `LAB_SOLUTION` | in the container, on *Run solution* — or by automation | the step can be solved without a human |

Progress lives in the learner's Dynatrace **user app-state**, not in the container, and each start, answer, completed step and completed training is emitted as a **bizevent** (`com.dynatrace.enablement.training.*`) — that is how you see who got how far.

## 4. Resume — rebuilt from the solutions

A container is disposable: it can be shut down to save cost, or lost — the **progress** survives. When the learner comes back, Orbital builds a fresh container (`post-create.sh`, `post-start.sh`) and then **replays the `LAB_SOLUTION` commands of every completed step, in order**, before handing it over. The learner lands where they left off.

Resume stops at the first completed step that changed the environment but has **no solution** (and no `LAB_NO_SOLUTION` marker). Solutions are forward-dependent, so skipping one would leave a state no author designed. **Every step with a solution is a step the environment can be rebuilt past.**

## 5. Night — the training tests itself

The nightly pipeline, for every active repo in the dynatrace-wwse [`repos.yaml`](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/repos.yaml):

- runs **`integration-test`** — builds the environment and runs `.devcontainer/test/integration.sh`;
- and, for repos tagged **`enablement-app`**, runs **`training-test`**: it provisions a real session with minted tokens and walks the training section by section — every `LAB_QUESTION` must parse, `STEP_SETUP` runs, the `LAB_SOLUTION` commands run (with `LAB_WAIT=1`), the solution's `verify` commands run, then every shell **and DQL** check of the section runs against the real tenant. Each section is PASS or FAIL.

A training whose solutions are complete is therefore **tested end to end every night** — when a Dynatrace release, an operator version or an app image breaks a step, you find out the next morning, not from a customer.

## 6. Deliver — self-service or workshop

The same training, unchanged, is delivered two ways:

- **Self-service** — any learner in any tenant with the app opens it from the catalog.
- **Workshop** — a trainer creates a workshop: a roster (one email per line) or a **join code**, two gates (**Open room** unlocks chat and the board; **Start** unlocks environments and steps), a **live board** with each learner's progress, **chat, raise-hand** and direct messages, and the **Workshop Pad** (welcome notes, solutions, Q&A — exportable when the workshop ends). Learners join **across tenants**; the trainer team can have up to 5 trainers.

## Codespaces vs. Orbital — same container, different host

| | Codespaces / Dev Containers | Orbital (the app) |
|---|---|---|
| Image | `shinojosa/dt-enablement` | same |
| `post-create.sh`, `post-start.sh` | run on create / start | run on every provision (and before a resume replay) |
| Dynatrace tokens | Codespaces secrets or `.devcontainer/.env` — **you** provide them | **minted** by the app from `dt-tokens.yaml` |
| Session id (`DT_HOSTGROUP`) | derived from `GITHUB_USER` + date | set by Orbital per learner |
| Terminal | VS Code | the app's terminal tab |
| Lesson UI | MkDocs on port 8000 / GitHub Pages | the app |

A training that works in a Codespace works on Orbital — that is the point of building on the framework.

<div class="grid cards" markdown>
- [02 — Automate the Environment :octicons-arrow-right-24:](02-automation.md)
</div>
