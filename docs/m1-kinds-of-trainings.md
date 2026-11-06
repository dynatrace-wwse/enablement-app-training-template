# 08 — Kinds of Trainings and Workshops

Before you write a step, decide **what kind of training** you are building and **how it may be delivered**. Three independent questions decide it:

| Question | The answer comes from | Values |
|---|---|---|
| Does the learner get a live environment? | **detected** — the repo has `.devcontainer/devcontainer.json` | **Hands-on** (environment, terminal) · **Self-paced** (Markdown and quizzes only) |
| May a learner start it alone? | **declared** — `availability` | `self-service` (default) · `workshop-only` |
| Which tenants may a workshop's learners come from? | **declared** — tenancy (`tenancy` / `type`) | `any` (default) · `single` (`same-tenant`) · `multi` (`multi-tenant`) |
| Does the room share one machine? | **derived** — the repo ships `.devcontainer/workshop-post-create.sh` | shared infrastructure yes / no |

Nothing is mandatory: a training with no declaration at all is **self-service, tenancy `any`, no shared infrastructure** — exactly how this training is delivered, so it can run in any tenant where the app is installed.

## The four kinds you will meet

| Kind | Environment | Example | What to declare |
|---|---|---|---|
| **Self-paced** | none | Learning Bytes, onboarding modules | nothing — no `.devcontainer` folder |
| **Hands-on, personal environment** | one container per learner (k3d cluster, apps, OneAgent) | [Kubernetes 101](https://github.com/dynatrace-wwse/enablement-kubernetes-101), this training | nothing — self-service, any tenant |
| **Workshop, single tenant** | personal environments, every learner in the **trainer's** tenant | a customer workshop on their own tenant | `tenancy: single` — joins from another tenant are refused (`single_tenant_workshop`) |
| **Workshop, shared infrastructure** | **one** machine for the whole room, built by `workshop-post-create.sh` | [Build Your Own Agent](https://github.com/dynatrace-wwse/enablement-build-your-own-agent) | `workshop-only` **and** `single` (same-tenant) — the only combination Orbital accepts for a shared machine |

A **multi-tenant** workshop — learners joining from their own tenants, each with a personal environment — is what the default (`any`) already allows: the bootcamps ran this way, 50 to 100 attendees across several tenants. *Multi-tenant shared infrastructure* is not built yet, so Orbital refuses it.

## Where you declare it: `.devcontainer/delivery.yaml`

One file next to the workshop scripts. When it exists it **wins** over the older `delivery:` block in the front matter of `docs/index.md`:

```yaml title=".devcontainer/delivery.yaml"
version: 1                   # required
type: same-tenant            # same-tenant | multi-tenant   (tenancy single | multi)
availability: workshop-only  # workshop-only | self-service (default self-service)
seats:
  personal: false            # learners get a personal environment (default true; false for shared)
  mode: full                 # full | dtctl-only (default full)
shared:                      # only with .devcontainer/workshop-post-create.sh
  instance: m6a.4xlarge      # the shared machine's shape — see "Sizing"
```

Rules Orbital enforces (and the framework's `sync check-delivery` lints the same way):

- An **unknown key or bad value** makes the file `invalid`. An invalid declaration **grants nothing**: availability and tenancy fall back to the defaults, and shared mode is refused.
- `workshop-post-create.sh` present → the file must say `type: same-tenant` **and** `availability: workshop-only`. A `shared:` block without the script is invalid.
- The file **and** an index.md block that disagree → `invalid` (two truths). If they agree, it is valid with a warning to remove the block.
- A `workshop-only` training started without a workshop is refused (`409 workshop_only`).

!!! tip "Keep a training deliverable everywhere"
    Declare only what you need. Every restriction — `workshop-only`, `single`, a shared machine — narrows where and how the training can run. A training meant for *any tenant where the app is installed* declares nothing.

## Check: how is this training delivered?

`describeTrainingDelivery` (in this repo's `my_functions.sh`) derives the answer the way Orbital does: is there a `workshop-post-create.sh`, a `delivery.yaml`, or a front-matter block? It fails when a shared script exists but nothing declares the delivery — the state Orbital refuses.

<!-- LAB_QUESTION
type: shell-verification
question: "Verify this training's delivery declaration is consistent"
buttonText: "Check delivery"
command: "describeTrainingDelivery"
expect:
  operator: contains
  value: "shared=no"
hint: "Run describeTrainingDelivery in the terminal. This training ships no workshop-post-create.sh, so shared infrastructure must be 'no'."
explanation: "No delivery block and no shared script: self-service, tenancy any — deliverable in every tenant."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "A training ships .devcontainer/workshop-post-create.sh. Which declaration lets a trainer run it as a shared workshop?"
options:
  - "Nothing — the script alone is enough"
  - "availability: workshop-only and type: same-tenant"
  - "availability: self-service and type: multi-tenant"
  - "seats.personal: true"
correct: 1
explanation: "Shared infrastructure is derived from the script, and it must be declared workshop-only and single-tenant (same-tenant). Multi-tenant shared is not built yet."
-->

<!-- LAB_NO_SOLUTION: reading step — the check only reads the repository, nothing to solve -->
