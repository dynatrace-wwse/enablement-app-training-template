# 14 — Validations: Problems, Checklist, Validate, Nightly

A training is proven by machines, at four levels — from every keystroke to every night:

| Level | When | What it proves | Where you see it |
|---|---|---|---|
| **Problems** (lint) | on every edit, in the browser | every block parses and can pass: no dropped question, MCQ `correct` in range, only known template variables, a `timeout` in 10..900, a solution per hands-on step, no starter placeholder left | the editor's **Problems** tab; errors block Publish |
| **Checklist** | while you author | what a machine cannot check: the check fails *before* the solution, the logo is approved, … | the **Checklist** tab; open `human-`/`submit-` items block Create PR |
| **Validate** | when you press it | the whole training, step by step, in a container | the **Runs** tab; a pass on a commit stamps it *Orbital Validate* ✓ on GitHub |
| **Nightly training-test** | every night, after merge | the same, on the default branch, against a real tenant | the training's nightly status |

## Problems — the lint you cannot skip

The editor lints the live buffers, so a broken block is flagged before you save. A few rules worth knowing by name:

| Rule | Severity | Means |
|---|---|---|
| `section-solution` | error | a hands-on step (it has a shell check or a setup) has no `LAB_SOLUTION` and no `LAB_NO_SOLUTION` reason |
| `question-dropped` | error | the importer would silently skip this question (missing `buttonText`, unknown operator, …) |
| `mcq-correct` | error | `correct` names no option — the learner can never pass |
| `dql-var` | error | an unknown template variable (double braces) in a DQL check — it would match nothing, silently |
| `solution-timeout` | error | `timeout:` is not a whole number from 10 to 900 |
| `placeholder` | error | starter text left in, or a check whose command is a no-op (`true`) |
| `dql-namespace` | warning | a Kubernetes DQL check without a `k8s.namespace.name` filter |
| `page-not-in-nav` | warning | a page `mkdocs.yaml` does not list |

## The Checklist — what only a person can tick

Items live in the training's own pages as HTML comments the learner never sees.

--8<-- "snippets/blocks/checklist.md"

`[ ]` open · `[x]` done · `[-]` n/a with a reason. `human-` and `submit-` items **block Create PR** while open; `author-` items never block; `gen-` items are ticked by the training generator. Per-step items go on the step's page, repo-wide ones on `docs/index.md`.

## Validate — two buttons, one validator

| Button | Runs in | Use it |
|---|---|---|
| **Validate in running environment** (two circles) | your environment as it is now | fast loop while you write a step |
| **Validate in a new container** | a **fresh** container built from the commit — it replaces the running one | before you publish: the only run that stamps a commit validated |

Stages, in order: `lint` (blocks parse, `timeout` in range, every function name a command calls is defined), `tokens` (every token `dt-tokens.yaml` declares is present), `post-create` / `post-start`, then **one stage per page**: setup → solution → check, then `dql` (every DQL check against the tenant) and `quizzes` (shown *Not verified* — a quiz has no machine answer, so it never blocks green). A failed row opens with the command, its output, the exit code and **Go to block**.

!!! tip "Make every check able to fail"
    Validate runs the solution, then the check. A check that always passes (`gte 0`, `true`) turns Validate green while proving nothing. Run each check once **before** its step's action and see it say no.

A PR from a branch whose head has no passing Validate is still possible — **Create PR without validation** — but the PR body says *Not validated by Orbital* and its check stays missing for reviewers.

## Nightly — content stays valid

After merge, the nightly training-test runs every solution and every check end to end against a real tenant. A training that passes one night and fails the next with unchanged pages usually means the environment, a host or the tenant changed — which is exactly what it is there to catch. A green streak there is the planned basis for a *nightly-tested* mark in the catalog (ENH-152, not shipped yet).

<!-- LAB_QUESTION
type: multiple-choice
question: "Which Validate run stamps a commit as validated, so Publish becomes the primary action?"
options:
  - "Validate in running environment"
  - "Validate in a new container"
  - "The Problems tab turning empty"
  - "Ticking every checklist item"
correct: 1
explanation: "Only a Validate in a fresh container built from the commit proves the training from scratch; its pass is recorded on the commit as Orbital Validate."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "A dql-verification uses {{SESSION_ID}} instead of {{DT_SESSION_ID}}. What happens?"
options:
  - "The app replaces it with an empty string and the check passes"
  - "Problems reports a dql-var error: the query would silently find nothing"
  - "Nothing until a learner complains"
  - "The nightly test fixes it"
correct: 1
explanation: "An unknown placeholder stays literal; inside quotes that is valid DQL matching nothing. The lint catches it before you can publish."
-->

<!-- LAB_NO_SOLUTION: reading step with knowledge checks — nothing changes in the environment -->
