# 00 — Getting Started for Trainers

This page explains the two systems you need to understand before authoring: **Orbital Operations server** (where the container runs) and the **Dynatrace enablement app** (where the learner sees the lesson). Once you understand how these two systems connect, every authoring decision makes sense.

---

## How Orbital hosts your training container

**Orbital** is an EC2-based FastAPI + Redis server at `autonomous-enablements.whydevslovedynatrace.com`. When a learner starts a training inside the Dynatrace app, Orbital:

1. Pulls your repo's container image (built from `.devcontainer/`)
2. Starts a dedicated Docker container per session using **Sysbox** (supports nested Docker and k3d clusters inside)
3. Exposes a **PTY bridge** — a WebSocket pseudo-terminal that the Dynatrace app connects to for the interactive terminal tab
4. Executes `shell-verification` commands inside the container when the learner clicks a check button
5. Tears down the container when the session ends

```
Learner (Dynatrace App)
       │
       ├── Terminal tab ──────────────── PTY bridge (WebSocket) ──► Orbital container
       ├── "Check X" button ──────────── shell-verification API ──► Orbital container
       ├── "Validate DQL" button ──────── dql-verification API ──► Dynatrace tenant
       └── Assessment ─────────────────── boundScenarioId ──────► .assessment/*.json
```

!!! tip "What `post-create.sh` does on Orbital"
    On Orbital, `post-create.sh` runs inside the container after it starts — same as in Codespaces. This is where your cluster is provisioned, apps are deployed, and the environment is configured. Keep `post-create.sh` fast: Orbital sessions time out if startup takes too long.

---

## How the Dynatrace app loads lessons

The Dynatrace enablement app reads your `mkdocs.yaml` `nav` section to build the lesson menu. For each page:

1. It fetches the rendered markdown from GitHub Pages (or your `gh-pages` branch)
2. It parses `<!-- LAB_QUESTION ... -->` and `<!-- STEP_SETUP ... -->` HTML comments to find interactive blocks
3. It renders each block as a UI element (button, MCQ, DQL runner, etc.)
4. It connects to Orbital to execute shell commands when the learner interacts

The static docs site and the interactive runtime are **separate concerns**:
- MkDocs renders the markdown → static HTML → GitHub Pages
- The Dynatrace app reads that HTML and adds interactivity at runtime

This means you can preview the lesson content locally (`mkdocs serve`) but interactive blocks only work when connected to Orbital.

---

## The authoring loop

```
1. Edit markdown in docs/      → adds lesson content + interactive blocks
2. Edit my_functions.sh        → adds/modifies custom shell functions
3. Edit .assessment/*.json     → adds/modifies scored assessments
4. git push + gh-pages deploy  → publishes the updated lesson
5. Orbital picks up changes    → no redeploy needed for markdown-only changes
6. Test in Dynatrace app       → verify every interactive block works
```

For structural changes (new functions, new container setup), you need to rebuild the container image and update Orbital. See `04-publishing-validation.md` for the full workflow.

---

## Credential wiring

Your training container gets three environment variables injected by Orbital at session start:

| Variable | Contains |
|---|---|
| `DT_ENVIRONMENT` | Learner's Dynatrace tenant URL (e.g. `https://abc123.apps.dynatrace.com`) |
| `DT_OPERATOR_TOKEN` | Operator token with K8s monitoring permissions |
| `DT_INGEST_TOKEN` | Ingest token for logs, metrics, and traces |

Framework functions (`dynatraceEvalReadSaveCredentials`, `generateDynakube`) read these variables and generate Kubernetes manifests automatically. Trainers do not need to handle credential injection manually.

---

## Your first authoring task

Before continuing, verify that your Codespace environment is ready. The check below confirms the k3d cluster is running — this is the same cluster your lessons will use.

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the k3d cluster is Running in your environment"
buttonText: "Check Cluster"
command: "kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'"
expect:
  operator: gt
  value: 0
hint: "The cluster is provisioned by post-create.sh. Wait 60 seconds after the Codespace starts and try again."
explanation: "Cluster is Ready — your authoring environment is set up correctly."
-->

!!! success "Ready to proceed?"
    Continue to **01 — Lesson Anatomy** to learn the structure of every lesson page.

<div class="grid cards" markdown>
- [01 — Lesson Anatomy :octicons-arrow-right-24:](01-lesson-anatomy.md)
</div>
