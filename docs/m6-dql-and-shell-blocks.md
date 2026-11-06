# 13 — DQL and Shell Blocks, Live

The full catalog of blocks is in [Interactive Blocks](04-interactive-blocks.md). This module shows the ones a training uses most — **live**, so you can press every button and see the editor validate it.

## DQL fences — a query the learner runs

A ` ```dql ` fence renders as a runnable, editable query with **Run** and **Open in Notebooks**. A result that can be drawn gets a **Table | Chart** toggle. These read only Grail's own system tables, so they answer in **every** tenant:

```dql
fetch dt.system.buckets
| fields name, table, retention_days
| sort name
| limit 10
```

### Dashlets — one fixed view

Name a view inside braces and the fence draws it: `.records`, `.raw`, `.timeseries`/`.line`, `.bar`, `.pie`/`.donut`, `.honeycomb`, `.gauge`, `.meter`, `.single`. Options go in the same braces (`title`, `timeframe` ≤ 24h, `empty`, `autorun`, `unit`, `min`, `max`, `thresholds`, …).

```dql { .single title="Grail buckets in this tenant" }
fetch dt.system.buckets
| summarize buckets = count()
```

```dql { .bar title="Buckets per table" }
fetch dt.system.buckets
| summarize buckets = count(), by:{table}
```

Write the attribute list with braces and a space after `dql` — ` ```dql chart ` is not recognised, and MkDocs would not render it. The Problems tab warns on an unknown view (`dql-view-unknown`), an unknown option (`dql-attr-unknown`) and a view the query cannot feed (`dql-view-shape`). A dashlet only runs a query whose first command reads (`fetch`, `timeseries`, …).

## `dql-verification` — a check against Grail

The check runs **in the learner's tenant, as the learner**, and gates *Next* until it passes. This one reads Davis/system events from the last 24 hours, which every active tenant has:

<!-- LAB_QUESTION
type: dql-verification
question: "Verify Grail answers a DQL check in your tenant"
buttonText: "Run DQL check"
dql: "fetch dt.system.events, from:now()-24h | summarize events = count()"
expect:
  operator: gte
  field: events
  value: 1
hint: "The query runs in the tenant you are signed in to. If it returns 0, the tenant has had no system events in 24 hours — sign in to an active tenant."
explanation: "Grail answered the check — dql-verification works in this tenant."
-->

For **your** training's data, a check must be scoped to the learner and bounded in time, or a previous session can make it pass:

```dql
fetch logs, from:now()-15m
| filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")
| filter k8s.namespace.name == "todoapp"
| limit 1
```

- `{{DT_SESSION_ID}}` is replaced per learner; the cluster name **ends with** it, so `==` never matches.
- In a Kubernetes training, filter `k8s.namespace.name` too — the `dql-namespace` lint warns when you do not: a cluster-only query passes on `kube-system` data the learner never produced.
- An unknown template variable in a check (anything but the names in [Template variables](04-interactive-blocks.md#template-variables-one-query-every-learner-isolated)) is a lint **error** (`dql-var`): inside quotes it is valid DQL that silently finds nothing.
- Each run of a DQL check in the editor spends the author's DQL mint budget (30 an hour per person). Test with one press, not a loop.

## `shell-verification` — a check in the container

The command runs in the learner's container with the framework and `my_functions.sh` loaded — write the function name, no `source` prefix:

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the Kubernetes node is Ready"
buttonText: "Check node"
command: "checkNodeReady"
expect:
  operator: exit-zero
hint: "The cluster starts in post-create.sh. Wait a minute and check again."
explanation: "checkNodeReady ran in your container and found a Ready node."
-->

`expect.operator` is `exit-zero`, `contains` / `not-empty` (stdout), or `gt`/`gte`/`eq` on a number. A check whose command is a no-op (`true`, `exit 0`) is a lint error: it can never fail, so it proves nothing.

## A step that changes the environment: `STEP_SETUP` + `LAB_SOLUTION` with `timeout`

**Your task:** scale the TODO app to two replicas.

```bash
kubectl scale deployment todoapp -n todoapp --replicas=2
kubectl rollout status deployment todoapp -n todoapp
```

`STEP_SETUP` runs silently each time this step opens — it only *prepares*, never does the learner's work. Here it makes sure the app exists, so the step can be started on its own:

<!-- STEP_SETUP
commands:
  - checkTodoAppRunning || deployTodoApp
-->

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the TODO app runs two replicas"
buttonText: "Check replicas"
command: "checkTodoAppReplicas 2"
expect:
  operator: exit-zero
hint: "Run kubectl scale deployment todoapp -n todoapp --replicas=2, wait for the rollout, then check again."
explanation: "Two ready replicas — the deployment scaled."
-->

<!-- LAB_SOLUTION
reveal: |
  Scale the deployment and wait for the rollout:
  `kubectl scale deployment todoapp -n todoapp --replicas=2`
timeout: 300
commands:
  - scaleTodoApp 2
verify:
  - LAB_WAIT=1 checkTodoAppReplicas 2
-->

What each part of the solution is for:

| Field | Used by |
|---|---|
| `reveal` | **Show solution** — Markdown for the learner |
| `commands` | **Run solution**, Validate, the **nightly training-test** and **resume** — run in order in the container |
| `verify` | run after `commands`, with `LAB_WAIT=1` so the check waits for the state instead of racing the rollout |
| `timeout` | whole seconds, **10..900** — the limit for **each** of this block's commands and verifies. Without it: learner *Run solution* 600 s per command / 300 s per verify, Validate 840 s / 660 s. Outside the range is a lint error (`solution-timeout`); several solution blocks on one page run as one, the longest `timeout` wins |

Raise `timeout` only for a solution that really runs long (an operator install, a large app). The editor's **Solution** insert adds all three parts — reveal, commands, verify — so none is forgotten.
