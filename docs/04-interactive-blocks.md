# 04 — Interactive Blocks

Every block the app understands, with its source and — where it makes sense — a **live** instance you can click on this page. Blocks are HTML comments: invisible on GitHub Pages, rendered as buttons, quizzes and panels in the app.

| Block | Purpose | Runs in |
|---|---|---|
| [`shell-verification`](#shell-verification-check-the-container) | check the container's state | the learner's container |
| [`dql-verification`](#dql-verification-check-grail) | check that telemetry reached Grail | the learner's tenant |
| [`multiple-choice`](#multiple-choice-check-the-understanding) | inline knowledge check | the app |
| [`LAB_SOLUTION`](#lab_solution-how-a-step-solves-itself) | the step's fix — *Run solution*, nightly test, resume | the learner's container |
| [`LAB_NO_SOLUTION`](#lab_no_solution-a-step-with-nothing-to-solve) | declares a step has nothing to solve | — |
| [`STEP_SETUP`](#step_setup-prepare-the-step-silently) | prepares the step when it opens | the learner's container |
| [`LAB_QUESTIONAIRE`](#lab_questionaire-a-scored-assessment) | scored assessment from `.assessment/<id>.json` | the app |
| [`instructor-code`](#instructor-code-a-workshop-gate) | a gate only the instructor can open | the app |

!!! warning "Blocks are parsed even inside code fences"
    Never paste a block into a ```` ```markdown ```` example — it becomes real. The examples below are included from `docs/snippets/blocks/` for exactly that reason. See [Lesson Anatomy](03-lesson-anatomy.md#never-write-a-block-inside-a-code-example).

---

## `shell-verification` — check the container

The command runs **in the learner's container** (the same shell as their terminal), and its output is compared with `expect`. The recommended form calls a check function from [`my_functions.sh`](02-automation.md#my_functionssh-your-functions) and passes on exit code 0:

--8<-- "snippets/blocks/shell-verification.md"

The command does not load your functions by itself — start it with `source .devcontainer/util/source_framework.sh >/dev/null 2>&1 &&`.

| Field | |
|---|---|
| `question`, `buttonText`, `command`, `expect` | required |
| `hint` | shown when the check fails — tell the learner what to do |
| `explanation` | shown when it passes — tell them what it means |

| `expect.operator` | Passes when |
|---|---|
| `exit-zero` | the command exits 0 — **recommended**, with a `checkX` function |
| `gt` + `value` | stdout parsed as an integer is greater than `value` |
| `contains` + `value` | stdout contains `value` |
| `not-empty` | stdout is not empty |

A raw one-liner works too — count with `grep -c` and compare with `gt`:

--8<-- "snippets/blocks/shell-verification-count.md"

Live — this runs the template's `checkNodeReady` in your container:

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the cluster node is Ready"
buttonText: "Check Cluster"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkNodeReady"
expect:
  operator: exit-zero
hint: "The cluster is started by post-create.sh. Wait a minute and try again."
explanation: "The cluster node is Ready."
-->

!!! tip "Write checks that fail fast and tell the truth"
    Always add `2>/dev/null` and `--no-headers` to `kubectl`, so an error cannot inflate a count. And make sure your check *can* fail: run it once before the step's action and confirm it says no.

---

## `dql-verification` — check Grail

The query runs **in the learner's tenant**, as the learner. `{{DT_SESSION_ID}}` is replaced before it runs (see [template variables](#template-variables-one-query-every-learner-isolated)).

--8<-- "snippets/blocks/dql-verification.md"

| `expect.operator` | Passes when |
|---|---|
| `not-empty` | the query returns at least one record |
| `gte` · `gt` · `eq` + `value` | the value of `field` (or the first field of the first record) compares true; `eq` compares as text |
| `contains` + `value` | that value contains `value` |

Compare a number with `field`:

--8<-- "snippets/blocks/dql-verification-field.md"

**Auto-poll** — telemetry takes a minute or two to arrive. Add `pollSeconds` (5–60) **and** `timeoutSeconds` (10–300) and the check re-runs by itself until it passes or times out, instead of making the learner click repeatedly. Give both or neither — one alone is dropped with an import warning.

!!! warning "`fetch spans`: bound it with `from:`, never `filter timestamp`"
    On spans `timestamp` is **null** (a span has `start_time` / `end_time`), so `| filter timestamp > now()-15m` returns nothing — the check fails as an empty result, which looks exactly like "the data never arrived". Use `from:now()-15m`, which works for logs too. `service.name` is null on spans as well — filter on `span.name` or `endpoint.name`.

Live — does your tenant answer?

<!-- LAB_QUESTION
type: dql-verification
question: "Verify your tenant answers a DQL query"
buttonText: "Run DQL"
dql: "fetch dt.entity.kubernetes_cluster | summarize count = count()"
expect:
  operator: gte
  field: count
  value: 0
hint: "The app could not run the query. Check that you are signed in to the tenant."
explanation: "The query ran in your tenant — DQL checks work here."
-->

### Template variables — one query, every learner isolated

A workshop puts many learners in **one** tenant. The app replaces these placeholders in lesson Markdown and in every `dql:` field — inline and in `.assessment/*.json` — so one query returns only *this* learner's data:

| Placeholder | Becomes | Use it for |
|---|---|---|
| `{{DT_SESSION_ID}}` | the learner's session id, `<user>-<yyyymmdd>`, e.g. `alice-20260811` | scoping Grail queries to the learner's cluster |
| `{{DT_TENANT}}` | the tenant URL, no trailing slash | links: `[Traces]({{DT_TENANT}}/ui/apps/dynatrace.distributedtraces)` |
| `{{JOB_ID}}` | the Orbital environment id | support references — never a DQL filter |

The framework names the learner's cluster `<repo>-<session id>` and only ever shortens the **repo** part (see [DynaKube](02-automation.md#the-dynakube-defaults-and-your-override)), so the filter is always `endsWith`:

```dql
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")   // correct
| filter k8s.cluster.name == "{{DT_SESSION_ID}}"           // never matches
```

- **Placeholders do not resolve in shell.** In a `command:`, a `LAB_SOLUTION` or a `STEP_SETUP`, read the environment instead: `$DT_HOSTGROUP` holds the same session id.
- **Entity queries cannot be scoped** — `dt.entity.*` carries no `k8s.cluster.name`. In a multi-learner training, check logs, spans or metrics.
- **Bound every query in time** (`from:now()-15m`) so a previous session cannot give a false pass.
- An unknown placeholder is left as literal text, never replaced with an empty string.

---

## `multiple-choice` — check the understanding

--8<-- "snippets/blocks/multiple-choice.md"

2 to 6 `options`; `correct` is the 0-based index. Double-check it — a wrong index strands the learner.

<!-- LAB_QUESTION
type: multiple-choice
question: "Where does a shell-verification command run?"
options:
  - "In the learner's container, the same shell as their terminal"
  - "In the Dynatrace tenant, as a DQL query"
  - "On the GitHub Pages site"
  - "In the trainer's browser"
correct: 0
explanation: "Orbital executes it in the learner's container — which is why it can call your my_functions.sh helpers."
-->

---

## `LAB_SOLUTION` — how a step solves itself

The solution is what makes a training **self-maintaining**. One block (or several, merged) per step:

--8<-- "snippets/blocks/lab-solution.md"

| Field | Used by |
|---|---|
| `reveal` | **Show solution** — Markdown explaining the fix |
| `commands` | **Run solution**, the **nightly training-test** and **resume** — executed in order in the learner's container (framework and `my_functions.sh` are loaded) |
| `verify` | run after `commands`; each must exit 0, proving the fix worked |

Who uses it:

- **Trainers** see *Show solution* / *Run solution* on every step — the way to rescue a stuck learner in a workshop. Learners see them only if a tenant admin enables **solutions mode**.
- The **nightly training-test** runs `commands` with `LAB_WAIT=1` (so your `checkX` helpers wait instead of failing fast), then `verify`, then the step's checks. A training with a solution on every step is tested end to end, every night.
- **Resume** replays the `commands` of every completed step into a fresh container. A step that changed the environment but has no solution is where resume stops.

Write `commands` as calls to functions in `my_functions.sh` (`restartTodoApp`) or framework functions (`dynatraceDeployOperator`, `deployApplicationMonitoring`), make them idempotent, and point `verify` at the same check the learner clicks.

---

## `LAB_NO_SOLUTION` — a step with nothing to solve

--8<-- "snippets/blocks/lab-no-solution.md"

For a step that changes nothing in the environment — reading, a quiz, a sanity check of what `post-create.sh` built. It tells coverage and resume that the missing solution is intentional. One per step; the text after the colon is the reason.

---

## `STEP_SETUP` — prepare the step silently

--8<-- "snippets/blocks/step-setup.md"

One per step. The commands run in the learner's container, **without a button**, each time the step opens — so they must be idempotent. Use it to prepare, never to do the learner's work: Kubernetes 101 uses it to *generate* the DynaKube file the learner then applies.

---

## `LAB_QUESTIONAIRE` — a scored assessment

A multi-question, scored assessment lives in `.assessment/<id>.json` and is placed on a step with one line (the name is spelled `QUESTIONAIRE`; the older `boundScenarioId:` still works):

--8<-- "snippets/blocks/questionaire.md"

`retake=false` allows one attempt; `retake=true` allows retakes. The `<id>` must equal the `id` in the JSON file, case-sensitive.

```json title=".assessment/my-training-quiz.json"
{
  "templateVersion": "1.0.0",
  "id": "my-training-quiz",
  "category": "CO",
  "title": "My Training — Knowledge Check",
  "description": "Validate the key concepts.",
  "difficulty": "beginner",
  "estimatedTime": 5,
  "questions": [
    {
      "id": "q1",
      "type": "multiple-choice",
      "title": "Rolling restart",
      "content": "What does `kubectl rollout restart` do?",
      "options": [
        { "id": "a", "text": "Replaces pods gradually", "isCorrect": true,  "explanation": "New pods start before old ones stop." },
        { "id": "b", "text": "Deletes every pod at once", "isCorrect": false, "explanation": "That would cause downtime." }
      ],
      "correctAnswer": "a",
      "explanation": "A rolling restart keeps the application available.",
      "points": 1000,
      "hints": ["Think about availability."]
    }
  ],
  "maxScore": 1000,
  "tags": ["my-training"],
  "learningObjectives": ["Explain what a rolling restart does."]
}
```

Questions can also be `"type": "dql-verification"` with a `dql` field (placeholders work there too; escape quotes in JSON). Validate the file with `python3 -m json.tool .assessment/<id>.json`. This template's own assessment:

<!-- LAB_QUESTIONAIRE: template-authoring-fundamentals retake=true -->

---

## `instructor-code` — a workshop gate

--8<-- "snippets/blocks/instructor-code.md"

The learner cannot continue until they enter a code the instructor reveals live — useful to pace a workshop. The code is generated and checked server-side: **never** write `code`, `secret`, `algorithm` or `salt` fields (they are stripped).

---

## Cards and links

--8<-- "snippets/blocks/cards.md"

- `hs-video` — a video card: `url|title|description`, with `|` written as `%7C`. YouTube links render as a thumbnail.
- `hs-doc` — a document card: `url|title|kind`, where kind is `powerpoint`, `pdf` or `word`.
- `dt-app` — a button that opens a Dynatrace app by id (`dynatrace.kubernetes`, `dynatrace.distributedtraces`, `dynatrace.notebooks`, …). The `(placeholder)` href is ignored.

<!-- LAB_NO_SOLUTION: reference page — the only check is a read-only sanity check of the provisioned cluster -->

<div class="grid cards" markdown>
- [05 — Example Lesson :octicons-arrow-right-24:](05-example-lesson.md)
</div>
