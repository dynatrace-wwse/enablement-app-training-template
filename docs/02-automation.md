# 02 — Automate the Environment

Everything a learner finds when their environment is ready — the cluster, Dynatrace, the demo apps, the scenario — is built by code in `.devcontainer/`. Nothing is built by hand, and nothing in this folder is specific to Orbital: the same files build the same environment in a Codespace, a Dev Container or the app.

```text
.devcontainer/
├── devcontainer.json            image + lifecycle hooks (its presence = "hands-on")
├── post-create.sh               ★ what gets built — the most important file
├── post-start.sh                runs after post-create, and on every Codespace restart
├── util/
│   ├── source_framework.sh      pulls the framework at a pinned version (do not edit)
│   └── my_functions.sh          ★ your functions — checks, scenarios, solutions
├── yaml/
│   ├── dt-tokens.yaml           ★ optional: the tokens the app mints for this training
│   ├── dynakube-config.yaml     ★ optional: your changes to the default DynaKube
│   └── gen/                     generated output (gitignored) — e.g. dynakube.yaml
└── test/integration.sh          assertions the nightly integration test runs
```

---

## `post-create.sh` — the most important file

`post-create.sh` runs once, when the environment is created — on Orbital, before the learner sees anything. It is a plain bash script that **calls functions**: the framework's, and yours.

```bash title=".devcontainer/post-create.sh"
#!/bin/bash
export SECONDS=0
source .devcontainer/util/source_framework.sh   # loads the framework + my_functions.sh

setUpTerminal          # zsh, powerlevel10k, aliases, the greeting
startK3dCluster        # the Kubernetes cluster (k3d is the default engine)
installK9s             # k9s for the learner

# --- Dynatrace ------------------------------------------------------------
dynatraceDeployOperator   # Helm-installs the operator + CSI driver + webhook
deployApplicationMonitoring   # generates and applies an AppOnly DynaKube

# --- Apps -----------------------------------------------------------------
deployTodoApp             # or: deployApp easytrade | deployApp astroshop | ...
# deployMyApp             # your own, from my_functions.sh

# --- Scenario -------------------------------------------------------------
# prepareScenario         # e.g. inject the fault the learner will hunt

finalizePostCreation      # REQUIRED: verifies the creation, reports errors in the greeting
printInfoSection "Your dev container finished creating"
```

**Decide what the learner does, and automate everything else.** If step 1 of your training is "install the Dynatrace Operator", leave `dynatraceDeployOperator` *out* of `post-create.sh` — it becomes that step's [solution](04-interactive-blocks.md#lab_solution-how-a-step-solves-itself) instead. If the training is about DQL on a running system, deploy everything here and start the learner in Grail. Kubernetes 101 leaves the operator and the DynaKube to the learner; the [EasyTrade sample lab `post-create.sh`](https://github.com/sergiohinojosa/easytrade-sample-lab/blob/main/.devcontainer/post-create.sh) automates both and deploys EasyTrade.

Keep it fast — the learner is waiting — and keep it idempotent: it runs again on every provision and before every [resume](01-how-it-works.md#4-resume-rebuilt-from-the-solutions).

`post-start.sh` runs right after `post-create.sh` (and on every Codespace restart). Use it for things that must happen on each start, such as `exposeMkdocs`.

Framework docs: [Container post-creation & start](https://dynatrace-wwse.github.io/codespaces-framework/framework/#container-post-creation-start) · [Cluster functions for post-create.sh](https://dynatrace-wwse.github.io/codespaces-framework/functions/#unified-cluster-api-use-these-in-post-createsh)

## Framework functions you will use

All of these are loaded into every shell. Full list: [Functions Reference](https://dynatrace-wwse.github.io/codespaces-framework/functions/).

| Function | What it does |
|---|---|
| `setUpTerminal` | zsh, p10k theme, aliases, greeting |
| `startK3dCluster` · `startCluster` · `stopCluster` · `deleteCluster` | cluster lifecycle; `*Cluster` follows `CLUSTER_ENGINE` (`k3d` default, `kind` alternative) |
| `installK9s` | installs k9s |
| `dynatraceDeployOperator` | installs the Dynatrace Operator (Helm) and its token secret |
| `deployDynatrace [mode]` | generates the DynaKube from the [config](#the-dynakube-defaults-and-your-override) and applies it; waits for the ActiveGate. No mode = the configured `mode:` (**`apponly`**) — from the framework release after 1.11.1; 1.11.1 and earlier default to `cloudnative`, so pass the mode or use `deployApplicationMonitoring` |
| `deployApplicationMonitoring` | `deployDynatrace apponly` — code injection via CSI, plus log module |
| `deployCloudNative` | `deployDynatrace cloudnative` — **does not work on k3d or on Orbital** (the OneAgent DaemonSet needs a real host); Kind outside Orbital only |
| `generateDynakube` | only writes `.devcontainer/yaml/gen/dynakube.yaml` (for a step where the learner applies it) |
| `dynatraceEvalReadSaveCredentials` | reads and validates `DT_ENVIRONMENT` + tokens from the environment |
| `deployApp [app] [-d]` | deploys (or `-d` undeploys) a framework app; bare `deployApp` lists them |
| `deployTodoApp` | the small TODO app used by Kubernetes 101 |
| `registerApp <name> <ns> <svc> <port>` | exposes a service through the ingress, in Codespaces, locally and on Orbital |
| `waitForPod <ns> <name>` · `waitForAllReadyPods <ns>` | block until pods are Ready |
| `installMkdocs` · `exposeMkdocs` · `deployGhdocs` | live docs preview on port 8000 · publish to GitHub Pages |
| `variablesNeeded VAR:true VAR2:false` | fail early if a required variable is missing |
| `finalizePostCreation` | required last call of `post-create.sh` |
| `printInfoSection` · `printInfo` · `printWarn` · `printError` | consistent output |

## Apps

The framework ships ready-to-deploy demo apps: `ai-travel-advisor`, `astroshop`, `bugzapper`, `easytrade`, `hipstershop`, `todoapp`, `unguard`, `opentelemetry-demo`.

```bash
deployApp               # list the apps
deployApp easytrade     # deploy by name (or number / letter)
deployApp easytrade -d  # undeploy
```

Each app is exposed through the ingress, so it opens in the browser the same way in a Codespace, locally and in the app. Framework docs: [To deploy an app](https://dynatrace-wwse.github.io/codespaces-framework/framework/#to-deploy-an-app) · [Nginx ingress + app exposure](https://dynatrace-wwse.github.io/codespaces-framework/framework/#nginx-ingress-app-exposure).

**Your own app** does not go into `deployApp` — that list belongs to the framework. Write a function in `my_functions.sh`, and call `registerApp` so it is reachable:

```bash title=".devcontainer/util/my_functions.sh"
deployMyApp(){
  printInfoSection "Deploying my app"
  kubectl create ns myapp 2>/dev/null || true
  kubectl -n myapp apply -f .devcontainer/apps/myapp/   # your manifests, in your repo
  waitForAllReadyPods myapp
  registerApp "myapp" "myapp" "myapp-frontend" 8080     # <name> <ns> <service> <port>
}
```

## `my_functions.sh` — your functions

`my_functions.sh` is loaded on top of the framework in **every** shell, so a function defined here can be called from four places — which is exactly why it exists:

| Called from | Example |
|---|---|
| `post-create.sh` | `deployMyApp`, `prepareScenario` |
| the learner's terminal | `injectFault` — "run this and watch Dynatrace" |
| a `shell-verification` check | `checkOperatorReady` |
| a `LAB_SOLUTION` | `restartTodoApp` |

Write each step's **check** and **solution** as functions here, and the lesson Markdown stays short: the same logic is reused by the learner, the check, the solution and the nightly test. This template's `my_functions.sh` contains the Kubernetes 101 check helpers (`checkNodeReady`, `checkOperatorReady`, `checkDynakube`, `checkOneAgentInjected`, …) and a solution helper (`restartTodoApp`) to copy from.

**The check pattern** (from Kubernetes 101): a check probes **once** and answers immediately for a learner's click, but **waits** for the expected state first when automation sets `LAB_WAIT=1` — so the nightly test and resume never race a rollout:

```bash
checkOperatorReady() {
  [ -n "${LAB_WAIT:-}" ] && waitForPod dynatrace operator          # automation waits
  if kubectl get pods -n dynatrace --no-headers 2>/dev/null | grep -E 'operator' | grep -q Running; then
    printInfo "Dynatrace Operator pod is Running"; return 0         # pass = exit 0
  fi
  printError "Dynatrace Operator is not running — run the install steps above, then check again"
  return 1
}
```

Rules: `return`, never `exit` (the file is sourced — `exit` kills the learner's shell); keep functions idempotent; send noise to `2>/dev/null`.

Framework docs: [Custom functions (`my_functions.sh`)](https://dynatrace-wwse.github.io/codespaces-framework/framework/#custom-functions-my_functionssh)

---

## Tokens: `dt-tokens.yaml`

In the app, **nobody pastes a token.** Before the container starts, the app mints the training's tokens **in the learner's own tenant** — scoped, named per learner, and valid for 4 hours — and Orbital writes each one into `.devcontainer/.env` under the variable name you chose. `post-create.sh` and your functions simply read `$DT_OPERATOR_TOKEN`, `$DT_INGEST_TOKEN`, or whatever you declared.

**Where the list comes from:**

1. your repo's **`.devcontainer/yaml/dt-tokens.yaml`**, if it exists — otherwise
2. the framework default: [`codespaces-framework/.devcontainer/yaml/dt-tokens.yaml`](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/.devcontainer/yaml/dt-tokens.yaml) — `DT_OPERATOR_TOKEN` + `DT_INGEST_TOKEN`, which is everything `dynatraceDeployOperator` and `deployApplicationMonitoring` need.

**If the defaults are enough, add no file.** Add one when your training needs another token — for example an API token your own function uses to create a dashboard or read entities:

```yaml title=".devcontainer/yaml/dt-tokens.yaml"
migrationStatus: migrated        # see below

tokens:
  # --- the two the framework needs: copy them, the file REPLACES the default ---
  - name_suffix: operator
    env_var: DT_OPERATOR_TOKEN
    scopes:                      # classic scopes (dotted names)
      - activeGateTokenManagement.create
      - activeGateTokenManagement.write
      - entities.read
      - settings.read
      - settings.write
      - DataExport
      - InstallerDownload
    platform_scopes:             # used where the tenant mints platform (dt0s16) tokens
      - fleet-management:activegate.connection-info:read
      - fleet-management:activegate.tokens:create
      - fleet-management:container-images:read
      - fleet-management:oneagent.connection-info:read
      - fleet-management:oneagents:download
      - settings:objects:read
      - settings:objects:write

  - name_suffix: ingest
    env_var: DT_INGEST_TOKEN
    scopes: [metrics.ingest, logs.ingest, events.ingest, openTelemetryTrace.ingest]
    platform_scopes:
      - openpipeline:logs:ingest
      - openpipeline:metrics:ingest
      - openpipeline:traces:ingest
      - storage:metrics:write

  # --- your own ---
  - name_suffix: api
    env_var: DT_API_TOKEN          # your functions read $DT_API_TOKEN
    aliases: [DT_BIZEVENTS_TOKEN]  # the same value under a second name
    scopes: [entities.read, settings.read]
```

| Field | |
|---|---|
| `name_suffix` | **required** — the token is named `enbl-<training>-<user>-<suffix>` in the tenant |
| `env_var` | **required** — the variable name the container receives. This is how you "name" a token. |
| `scopes` | classic scopes (`metrics.ingest`, `entities.read`, …) |
| `platform_scopes` | platform scopes (`storage:logs:read`, `openpipeline:logs:ingest`, …) used when the token is minted as a platform token; if absent, `scopes` is translated |
| `kind` | `classic` (default) or `platform` — `platform` always mints a `dt0s16` platform token, and then `scopes` holds platform scope names |
| `aliases` | extra variable names that receive the same value |
| `migrationStatus` | top level: `migrated` (proven on tenants that no longer create classic tokens), `pending` (default), `legacy-classic-only` (needs a classic-only capability — the only value that refuses a workshop at creation) |

!!! warning "The repo file REPLACES the default — it is not merged"
    Adding one token means copying the operator and ingest tokens too, or the environment starts without them and the Dynatrace deployment fails. A file with an empty or missing `tokens:` list does **not** fall back to the framework file. Declare exactly what the training needs — the app mints exactly that.

A complete real example, with the reasoning for every scope: [Kubernetes 101 `dt-tokens.yaml`](https://github.com/dynatrace-wwse/enablement-kubernetes-101/blob/main/.devcontainer/yaml/dt-tokens.yaml). Framework docs: [Tokens: `dt-tokens.yaml`](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#tokens-dt-tokensyaml).

**Outside the app nothing is minted.** In a Codespace, set the same variable names as Codespaces secrets; locally, put them in `.devcontainer/.env` (gitignored):

```bash title=".devcontainer/.env"
DT_ENVIRONMENT=https://abc12345.apps.dynatrace.com
DT_OPERATOR_TOKEN=dt0c01.XXXX...
DT_INGEST_TOKEN=dt0c01.YYYY...
```

Framework docs: [Secrets & environment](https://dynatrace-wwse.github.io/codespaces-framework/instantiation-types/#secrets-environment)

---

## The DynaKube: defaults and your override

There is no DynaKube manifest to maintain. `deployDynatrace` (and `generateDynakube`) **generate** it at run time into `.devcontainer/yaml/gen/dynakube.yaml`, from two flat YAML files:

1. **Defaults** — [`codespaces-framework/.devcontainer/yaml/dynakube-defaults.yaml`](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/.devcontainer/yaml/dynakube-defaults.yaml), owned by the framework. Do not copy or edit it in your repo.
2. **Your override** — **`.devcontainer/yaml/dynakube-config.yaml`** in your repo. Only the keys you write change; everything else keeps the default. It is never touched by framework syncs.

```yaml title=".devcontainer/yaml/dynakube-config.yaml"
# flat key: value pairs only — nested YAML is ignored
kspm: true             # Kubernetes security posture management
extensions: true       # e.g. for Prometheus scraping
ag_memory_limit: "2Gi"
```

| Key | Default | |
|---|---|---|
| `mode` | `apponly` | `apponly` · `k8s-only` (ActiveGate only, no OneAgent) · `cloudnative` (not on k3d/Orbital) |
| `operator_version` · `dynakube_api_version` | pinned by the framework | |
| `log_monitoring` | `true` | the log module — container logs to Grail, no restart needed |
| `telemetry_ingest` | `true` | OTLP / telemetry endpoints |
| `sensitive_data` | `true` | |
| `kspm` · `extensions` | `false` | |
| `routing` · `debugging` · `dynatrace_api` | `true` · `false` · `false` | ActiveGate capabilities |
| `ag_replicas`, `ag_cpu_*`, `ag_memory_*` | `1`, `100m`/`500m`, `512Mi`/`1Gi` | ActiveGate resources |

The authoritative list is the defaults file itself. Framework docs: [DynaKube configuration](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#dynakube-configuration-defaults-and-repo-override) · [keys reference](https://dynatrace-wwse.github.io/codespaces-framework/functions/#dynakube-configuration).

**Why the name matters.** The DynaKube name, and the Kubernetes cluster name Dynatrace sees, is `<repo without "enablement-">-<session id>`, where the session id is `DT_HOSTGROUP` (`<user>-<yyyymmdd>`, set by Orbital per learner). The repo part is shortened to fit the operator's name limit; the session id **always survives whole at the end**. That is what makes `filter endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")` isolate one learner's telemetry in a shared tenant — see [Template variables](04-interactive-blocks.md#template-variables-one-query-every-learner-isolated).

---

## Check it

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the todoapp deployed by post-create.sh is Running"
buttonText: "Check todoapp"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkTodoAppRunning"
expect:
  operator: exit-zero
hint: "post-create.sh deploys it with deployTodoApp. Run `kubectl get pods -n todoapp` in the terminal to see its state."
explanation: "todoapp is Running — deployed by post-create.sh with no learner action."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "Your training needs an extra token, DT_API_TOKEN, besides the defaults. What goes in your repo's .devcontainer/yaml/dt-tokens.yaml?"
options:
  - "The operator and ingest tokens copied from the framework default, plus the new DT_API_TOKEN entry"
  - "Only the new DT_API_TOKEN entry — it is merged with the framework default"
  - "Nothing — export DT_API_TOKEN in post-create.sh"
  - "The token value itself, so the app can inject it"
correct: 0
explanation: "A repo dt-tokens.yaml replaces the default rather than merging with it, so it must list every token the training needs. It holds names and scopes only — the app mints the values."
-->

<!-- LAB_SOLUTION
reveal: |
  `post-create.sh` deploys the TODO app with `deployTodoApp`. If it is not running,
  deploy it again — the "Run solution" button does exactly that.
commands:
  - deployTodoApp
verify:
  - kubectl get pods -n todoapp --no-headers 2>/dev/null | grep -q Running
-->

<div class="grid cards" markdown>
- [03 — Lesson Anatomy :octicons-arrow-right-24:](03-lesson-anatomy.md)
</div>
