# 10 — dtctl and Monaco, Opt-in

The framework installs two Dynatrace command-line tools when a training asks for them — like the MCP server, they are **opt-in**:

| Tool | What a training uses it for | Token it reads (by **name**) |
|---|---|---|
| [`dtctl`](https://github.com/dynatrace-oss/dtctl) | query and inspect the tenant: DQL, documents, settings | `DT_DTCTL_TOKEN` |
| [`monaco`](https://github.com/Dynatrace/dynatrace-configuration-as-code) | configuration as code: deploy dashboards, notebooks, settings per learner | `DT_MONACO_TOKEN` |

A training opts in with one line in `post-create.sh`, **before** `setUpTerminal`. `setUpTerminal` then runs `installDTTools` first thing in post-create, so every later step and every lab step finds the tools. This training does:

```bash title=".devcontainer/post-create.sh"
export DT_TOOLS=all          # or: dtctl | monaco | dtctl,monaco
setUpTerminal
```

`installDTTools` installs them at the framework's pinned versions (`DTCTL_VERSION`, `MONACO_VERSION` in the framework's `variables.sh`), each **checksum-verified** against a hash committed in the framework. It is **never fatal** — a failed download is one `devtools (non-fatal)` warning and post-create carries on. An unknown `DT_TOOLS` entry is a warning. Without `DT_TOOLS` nothing is installed, and the terminal says `Type 'installDTTools' to install dtctl + Monaco` — a learner can do that in any training. `deployMonaco` installs Monaco itself, so it needs no opt-in; a step that runs `dtctl` does.

## Where the token comes from

Under Orbital the **app** mints one platform token per learner seat and delivers it under **both** names. Your repo's `dt-tokens.yaml` does not declare these two — a spec under either name is dropped. When the seat has a token, `installDTTools` also runs `enableDtctl`: a context named `enablement`, safety level **readonly**, holding a *reference* to `${DT_DTCTL_TOKEN}`, never the value.

!!! danger "The token can write; dtctl's safety level is what stops it"
    The seat token carries `document:documents:read/write/delete` and `settings:objects:read/write` besides the Grail reads. The `readonly` context is a **client-side** guard. Write steps as reads, and **never run `dtctl config view`** — it prints the resolved token.

A seat can be built without a token (the owner's platform-token cap, a tenant with no registered OAuth client). The app says so on screen, and dtctl is then installed with no context — which is exactly what the check below tells you.

## Check: the tools are installed

<!-- LAB_QUESTION
type: shell-verification
question: "Verify dtctl and Monaco are on PATH"
buttonText: "Check dev tools"
command: "checkDevTools"
expect:
  operator: exit-zero
hint: "installDTTools runs at the start of post-create.sh (setUpTerminal, because DT_TOOLS=all). Open the Provisioning Log and look for 'devtools (non-fatal)', or type installDTTools."
explanation: "Both tools were installed by setUpTerminal (DT_TOOLS=all), checksum-verified, at the framework's pinned versions."
-->

## Check: dtctl reads your tenant

`checkDtctlQuery` runs one read-only query through dtctl — the list of Grail buckets, which every tenant has — and fails with the reason when the seat has no token:

```bash
dtctl query -o json "fetch dt.system.buckets | summarize buckets = count()"
```

<!-- LAB_QUESTION
type: shell-verification
question: "Verify dtctl can query your tenant"
buttonText: "Query with dtctl"
command: "checkDtctlQuery"
expect:
  operator: exit-zero
hint: "If it says DT_DTCTL_TOKEN is not set, this seat was built without a dtctl token — the app shows why on the environment screen."
explanation: "dtctl ran a DQL query in your tenant with the seat's read-only context."
-->

## Monaco: configuration per learner

Deploying configuration is **opt-in**, from your `post-create.sh`:

```bash
deployMonaco tenant   # early: tenant-only config (dashboards, notebooks, settings)
startK3dCluster
deployTodoApp
deployMonaco env      # after the app answers: config that needs it
```

```text
monaco/
├── tenant/<any>/config.yaml + templates   deployed by `deployMonaco tenant`
└── env/<any>/config.yaml + templates      deployed by `deployMonaco env`
```

- The repo ships **no manifest**. `deployMonaco` writes one at run time with project name `<repo>-<DT_SESSION_ID>`, so learners in one tenant never overwrite each other. It refuses when there is no session id.
- Use the exported **`LEARNER_PREFIX`** in every `name:` so a learner finds their own objects.
- Supported types (v1): **`document`** (dashboards, notebooks) and **`settings`**. Anything else is refused, nothing deployed.
- **Cleanup is part of the design.** Before deploying, `deployMonaco` snapshots the phase and a Monaco delete file; `undeployMonaco [tenant|env]` deletes what was deployed. A training that writes into a learner's tenant must call it in its cleanup step.

```yaml title="monaco/tenant/dashboards/config.yaml"
configs:
  - id: my-dashboard
    config:
      name:
        type: environment
        name: LEARNER_PREFIX
      template: dashboard.json
    type:
      document:
        kind: dashboard
```

This training deploys nothing with Monaco on purpose: it must run in **any** tenant, and a master workshop that writes documents into every customer's tenant would need a cleanup step every learner reaches. Framework reference: [dtctl & Monaco](https://dynatrace-wwse.github.io/codespaces-framework/dtctl-monaco/).

<!-- LAB_QUESTION
type: multiple-choice
question: "Two learners share one tenant and both run deployMonaco. Why do their dashboards not overwrite each other?"
options:
  - "Monaco locks the tenant while it deploys"
  - "Each learner's project is named <repo>-<DT_SESSION_ID>, and names use LEARNER_PREFIX"
  - "The app gives each learner a separate tenant"
  - "dtctl's readonly context blocks the second deploy"
correct: 1
explanation: "deployMonaco writes a per-learner manifest at run time; the project name carries the session id, and LEARNER_PREFIX makes each object's name the learner's own."
-->

<!-- LAB_NO_SOLUTION: read-only checks — nothing is written to the tenant or the cluster -->
