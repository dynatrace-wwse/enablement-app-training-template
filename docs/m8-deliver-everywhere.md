# 15 — Deliver It: Catalog, Profiles and Workshops

A merged training reaches learners through three things: the **catalog** that names it, the **profile** that gives it to a tenant, and the **way** a trainer or learner starts it. Merge and refresh are covered in [Publish & Ship](06-test-publish-ship.md).

## The training's identity and its name

| | Comes from | Changes with |
|---|---|---|
| **Identity** | the GitHub repository, `<org>/<repo>` — e.g. `dynatrace-wwse/enablement-app-training-template` | a repo rename only — and that orphans imports, workshops and nightly history keyed by it |
| **Display name** | `mkdocs.yaml`: `training_name:` first, else `site_name:` without its "Dynatrace Enablement Lab: " prefix, else the repo name. The public Hub page uses the `title` in the framework's `repos.yaml` | an edit to `mkdocs.yaml` — a normal PR |
| **Catalog card** | front matter of `docs/index.md`: `description`, `tags`, `difficulty`, `duration` | a normal PR |

That is how this training became **How to Create Trainings** without its repository name changing: `training_name` and `site_name` in `mkdocs.yaml`, and the Hub `title` in `repos.yaml`.

```yaml title="mkdocs.yaml"
# Display name Orbital shows for this training (mkdocs warns about the unknown key — expected).
training_name: "How to Create Trainings"
```

## Profiles: which tenants get which trainings

A **profile** is a named set of trainings; Orbital's content service resolves a tenant to its profile — a tenant-specific mapping first, then the domain's default, then **`all`**. A training in the `all` profile is therefore offered to any tenant where the app is installed and no narrower profile applies. Profiles reference trainings in the managed **source catalog** (Orbital's Trainings tab), which is also where private repositories for customer workshops are added.

A training that must run in *any* tenant is built for it: no tenant-specific data in a check, read-only queries against tables every tenant has, nothing written to the tenant without a cleanup step. This training follows those rules — every check in it passes in a fresh tenant.

## Starting it: self-service, single-tenant or multi-tenant workshop

| Way | Who starts it | Tenants | Needs |
|---|---|---|---|
| **Self-service** | the learner, from the catalog | their own | `availability: self-service` (the default) |
| **Workshop, multi-tenant** | the trainer creates it; learners join with a code | each learner's own tenant | tenancy `any` (the default) |
| **Workshop, single tenant** | the trainer; learners join with a code | the **trainer's** tenant only — other tenants are refused | `tenancy: single` / `type: same-tenant` |
| **Workshop, shared infrastructure** | the trainer; one machine for the room | the trainer's tenant | `workshop-post-create.sh` + `workshop-only` + `same-tenant` ([module 11](m4-shared-workshops.md)) |

Every workshop gives the trainer the live board (each learner's progress), chat and raised hands, the Workshop Pad, `unlockPath`/`gateAhead` pacing, and the provisioning window ([Sizing](m5-sizing.md)). Two gates run it: **open room** turns on chat, board and hands; **start** turns on environments and steps. Ending a workshop terminates its environments.

<!-- LAB_QUESTION
type: multiple-choice
question: "You want to rename a training's title in the catalog. What do you change?"
options:
  - "Rename the GitHub repository"
  - "training_name in mkdocs.yaml"
  - "The first heading of docs/index.md"
  - "The workshop's name when you create it"
correct: 1
explanation: "Orbital names a training from training_name in mkdocs.yaml first (then site_name, then the repo name). The repository name is the training's identity — renaming it orphans everything keyed by it."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "A customer wants a workshop where every attendee works in the customer's own tenant, and nobody may join from elsewhere. Which declaration?"
options:
  - "Nothing — the default is single tenant"
  - "tenancy: single (type: same-tenant)"
  - "availability: workshop-only only"
  - "A workshop-post-create.sh"
correct: 1
explanation: "tenancy single stamps the workshop single-tenant; a learner whose tenant is not the workshop owner's is refused. The default (any) allows every tenant."
-->

<!-- LAB_NO_SOLUTION: reading step with knowledge checks — nothing changes in the environment -->
