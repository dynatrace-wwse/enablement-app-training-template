# ORBITAL_AND_APP.md — Runtime Architecture

This document explains how the Orbital Operations server and the Dynatrace app work together to deliver interactive enablement trainings. Read this before debugging interactive blocks or onboarding a new training.

---

## System overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Learner's browser                                               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Dynatrace App — Enablement Plugin                        │   │
│  │                                                            │   │
│  │  ┌──────────────┐  ┌──────────────────┐  ┌────────────┐  │   │
│  │  │  Lesson UI   │  │  Terminal tab    │  │ Assessment │  │   │
│  │  │  (markdown   │  │  (PTY WebSocket) │  │ (scored)   │  │   │
│  │  │  + blocks)   │  │                  │  │            │  │   │
│  │  └──────┬───────┘  └────────┬─────────┘  └────────────┘  │   │
│  │         │                   │                              │   │
│  └─────────┼───────────────────┼──────────────────────────── ┘   │
│            │                   │                                  │
└────────────┼───────────────────┼──────────────────────────────── ┘
             │ HTTPS API          │ WebSocket (PTY)
             ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│  Orbital Operations Server                                       │
│  autonomous-enablements.whydevslovedynatrace.com                │
│                                                                  │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │  FastAPI         │  │  Redis           │  │  PTY Bridge   │  │
│  │  (job runner,    │  │  (job queue,     │  │  (WebSocket → │  │
│  │  REST API)       │  │  session state)  │  │  container    │  │
│  │                  │  │                  │  │  shell)       │  │
│  └────────┬─────────┘  └──────────────────┘  └───────┬───────┘  │
│           │                                           │          │
│           ▼                                           ▼          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Docker (Sysbox runtime)                                    │ │
│  │                                                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Training container (shinojosa/dt-enablement:v1.2)   │  │ │
│  │  │                                                        │  │ │
│  │  │  k3d cluster  +  demo apps  +  framework functions    │  │ │
│  │  │  DT_ENVIRONMENT  DT_OPERATOR_TOKEN  DT_INGEST_TOKEN   │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
             │ DQL queries
             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Learner's Dynatrace Tenant                                      │
│  https://<tenant-id>.apps.dynatrace.com                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Orbital container lifecycle

### Provisioning

When a learner clicks **Start Environment** in the Dynatrace app:

1. Orbital receives a `POST /provision` request with the learner's session ID and training ID
2. Orbital pulls the container image (`shinojosa/dt-enablement:v1.2` by default)
3. Sysbox starts the container with full unprivileged nested container support
4. Orbital injects credentials as environment variables: `DT_ENVIRONMENT`, `DT_OPERATOR_TOKEN`, `DT_INGEST_TOKEN`
5. `post-create.sh` runs inside the container (k3d cluster, demo app deployment, etc.)
6. When ready, Orbital signals the Dynatrace app — the learner sees "Environment Ready"

### Runtime

While the session is active:

- **PTY bridge**: Orbital opens a PTY inside the container and exposes it over WebSocket. The Terminal tab in the Dynatrace app connects to this WebSocket. Keystrokes and resize events flow as binary/JSON frames.
- **Shell verification**: when the learner clicks a check button, the Dynatrace app sends the `command` string to Orbital's REST API. Orbital runs it in the container and returns stdout. The app compares the output to `expect`.
- **STEP_SETUP**: when the learner navigates to a page with STEP_SETUP, the app calls Orbital to run the listed commands before rendering the page.
- **DQL verification**: the Dynatrace app itself runs the DQL query against the learner's tenant. Orbital is not involved in DQL execution.

### Teardown

- When the session ends (learner closes app, timeout, or explicit stop), Orbital stops and removes the container.
- Container state is ephemeral. Do not rely on container state across sessions.
- Persistent state must live in the Dynatrace tenant (entities, logs, metrics) or be re-created by `post-create.sh`.

---

## Sysbox — why nested containers work

Standard Docker containers cannot run Docker-in-Docker or k3d without `--privileged` mode (security risk). Orbital uses [Sysbox](https://github.com/nestybox/sysbox), a container runtime that provides:

- Full filesystem isolation (`/proc`, `/sys` namespacing)
- Unprivileged nested Docker daemon
- k3d cluster support (containerd inside the container)
- Seccomp + AppArmor compatibility

From the trainer's perspective: write `post-create.sh` as you would for Codespaces — k3d, Docker, and kubectl all work normally inside the Orbital container.

---

## PTY bridge — how the terminal works

The Terminal tab in the Dynatrace app is a full interactive pseudo-terminal:

- **Binary frames**: keystrokes are sent as `TextEncoder`-encoded binary WebSocket frames (not text)
- **JSON frames**: resize events are JSON (`{"type": "resize", "cols": N, "rows": N}`)
- **Shell**: defaults to `zsh` with the framework's p10k theme
- **Functions**: all framework functions and `my_functions.sh` functions are sourced automatically

Trainers can use the terminal for any interactive scenario — `kubectl exec`, `vim`, `k9s`, REPL sessions, etc.

---

## Credential injection

| Variable | Value source | How it's used |
|---|---|---|
| `DT_ENVIRONMENT` | Learner's tenant URL | `dynatraceEvalReadSaveCredentials` reads this to build the Kubernetes Secret |
| `DT_OPERATOR_TOKEN` | Token created in the learner's tenant | Operator authentication |
| `DT_INGEST_TOKEN` | Token created in the learner's tenant | Log/metric/trace ingest |

Trainers do not manage credential injection. Orbital injects these at container start. The framework functions read them.

---

## GitHub Pages ↔ Dynatrace app content flow

```
Trainer edits docs/ markdown
        │
        ▼
git push + deployGhdocs (or GitHub Actions merge)
        │
        ▼
GitHub Pages (gh-pages branch)
https://dynatrace-wwse.github.io/<repo-name>/
        │
        ▼ (Dynatrace app fetches rendered HTML)
Dynatrace app parses <!-- LAB_QUESTION --> comments
        │
        ├── Renders interactive blocks
        ├── Calls Orbital for shell-verification
        └── Runs DQL in learner's tenant
```

Lesson content updates (markdown only) take effect after `deployGhdocs` — no Orbital restart needed. Container changes (new functions, new apps) require rebuilding and re-publishing the Docker image, then notifying the Orbital administrator.

---

## Codespaces vs Orbital — same container, different host

| Aspect | Codespaces | Orbital |
|---|---|---|
| Container image | `shinojosa/dt-enablement:v1.2` | Same image |
| `post-create.sh` | Runs once at container creation | Runs once at container provision |
| `post-start.sh` | Runs on each Codespace resume | Not used (Orbital sessions are one-shot) |
| Terminal | VS Code integrated terminal | Dynatrace app PTY tab |
| Port forwarding | VS Code Ports tab | Not needed (Orbital manages routing) |
| Credentials | GitHub Codespace secrets | Injected by Orbital |
| Lesson UI | Local MkDocs (port 8000) or GitHub Pages | Dynatrace app (GitHub Pages) |

Both modes use the same framework functions. A training that works in Codespaces will work on Orbital.

---

## Debugging interactive blocks

### Shell verification fails unexpectedly

1. Open the Terminal tab in the Dynatrace app (or the Codespace terminal)
2. Run the `command` string manually
3. Check the raw output — look for error messages, unexpected whitespace, or empty results
4. Common fixes:
   - Add `2>/dev/null` to suppress errors that inflate `grep -c`
   - Use `--no-headers` with kubectl to avoid counting the header row
   - Wait for resources to reach Running state before the check runs

### DQL verification returns no results

1. Open Notebooks in your Dynatrace tenant
2. Run the DQL query manually to see what it returns
3. Common fixes:
   - Add `filter timestamp > now() - 10m` to scope to recent data
   - Generate the expected state first (e.g., create a log entry, restart a pod)
   - Check tenant permissions — `DT_OPERATOR_TOKEN` and `DT_INGEST_TOKEN` must have the correct scopes

### STEP_SETUP fails silently

1. Run the commands manually in the terminal to see errors
2. Check that the framework is sourced: `source .devcontainer/util/source_framework.sh`
3. Verify the function exists: `type generateDynakube`
4. Check `.devcontainer/yaml/gen/` for the generated output

### Assessment does not appear

1. Verify `boundScenarioId` matches the `id` field in the JSON file exactly (case-sensitive)
2. Confirm the JSON file is in `.assessment/` at repo root (hidden directory)
3. Validate JSON syntax: `python3 -m json.tool .assessment/<id>.json`
4. Check `retake` — if `retake=false` and the learner already completed it, it won't show again

---

## Infrastructure contacts

| System | Contact |
|---|---|
| Orbital Operations server | Orbital administrator (Slack: #enablement-orbital) |
| Dynatrace app enablement plugin | DT App team |
| Container image (`dt-enablement`) | Framework team (codespaces-framework repo) |
| GitHub org permissions | WWSE IT |
