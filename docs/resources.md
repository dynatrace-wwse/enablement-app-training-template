# Resources

## This template, by topic

| I want to… | Go to |
|---|---|
| understand why interactive content matters | [Welcome](index.md) |
| follow the path from zero to a shipped training | [00 — Getting Started](00-getting-started.md) |
| know what happens when a learner clicks *Start* | [01 — How It Works](01-how-it-works.md) |
| write `post-create.sh`, add an app, write `my_functions.sh` | [02 — Automate the Environment](02-automation.md) |
| get an extra Dynatrace token minted for my training | [02 → Tokens](02-automation.md#tokens-dt-tokensyaml) |
| change the DynaKube (mode, KSPM, extensions, ActiveGate size) | [02 → DynaKube](02-automation.md#the-dynakube-defaults-and-your-override) |
| structure a step | [03 — Lesson Anatomy](03-lesson-anatomy.md) |
| look up a block's fields and operators | [04 — Interactive Blocks](04-interactive-blocks.md) |
| copy a complete lesson | [05 — Example Lesson](05-example-lesson.md) |
| test, publish and ship | [06 — Test, Publish & Ship](06-test-publish-ship.md) |

## Reference training

- [enablement-kubernetes-101](https://github.com/dynatrace-wwse/enablement-kubernetes-101) — the golden example: checks, quizzes, DQL validations and a solution on every step. Read its `docs/`, `.devcontainer/util/my_functions.sh` and `.devcontainer/yaml/dt-tokens.yaml` side by side.
- [EasyTrade sample lab `post-create.sh`](https://github.com/sergiohinojosa/easytrade-sample-lab/blob/main/.devcontainer/post-create.sh) — Kubernetes 101 cloned, with the operator, DynaKube and EasyTrade automated in `post-create.sh`.

## Codespaces Framework

- [Framework docs](https://dynatrace-wwse.github.io/codespaces-framework) — cache, functions, sync, local mode, testing
- [Functions reference](https://dynatrace-wwse.github.io/codespaces-framework/functions/)
- [Container post-creation & start](https://dynatrace-wwse.github.io/codespaces-framework/framework/#container-post-creation-start)
- [Custom functions (`my_functions.sh`)](https://dynatrace-wwse.github.io/codespaces-framework/framework/#custom-functions-my_functionssh)
- [Deploying an app](https://dynatrace-wwse.github.io/codespaces-framework/framework/#to-deploy-an-app)
- [Tokens: `dt-tokens.yaml`](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#tokens-dt-tokensyaml) · [the default file](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/.devcontainer/yaml/dt-tokens.yaml)
- [DynaKube configuration](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#dynakube-configuration-defaults-and-repo-override) · [the defaults file](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/.devcontainer/yaml/dynakube-defaults.yaml)
- [Live documentation, locally (`installMkdocs`)](https://dynatrace-wwse.github.io/codespaces-framework/framework/#live-documentation-locally)
- [K3d vs Kind](https://dynatrace-wwse.github.io/codespaces-framework/framework/#kubernetes-cluster)
- [Secrets & environment (local `.env`)](https://dynatrace-wwse.github.io/codespaces-framework/instantiation-types/#secrets-environment)

## Orbital and the app

- Register a tenant and install the app: [autonomous-enablements.whydevslovedynatrace.com/#register](https://autonomous-enablements.whydevslovedynatrace.com/#register)
- No tenant of your own: use the SE sandbox tenant (ask in the enablement channel)

## MkDocs Material

- [MkDocs Material reference](https://squidfunk.github.io/mkdocs-material/reference/) — admonitions, code blocks, grids, icons
- [MkDocs snippets](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#snippets) — `--8<--` include syntax

## Dynatrace

- [DQL reference](https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-query-language) — full DQL syntax
- [Dynatrace Operator for Kubernetes](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/deployment)
- [DynaKube custom resource reference](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/reference/dynakube)
- [Dynatrace App Toolkit](https://dt-url.net/app-toolkit) — App IDs for `dt-app` deep links

## GitHub Codespaces

- [GitHub Codespaces docs](https://docs.github.com/en/codespaces)
- [devcontainer.json reference](https://containers.dev/implementors/json_reference/)
- [Codespace lifecycle hooks](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers#devcontainerjson)

## Quick reference — kubectl commands for trainers

```bash
# Cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Watch pod lifecycle
kubectl get pods -n <namespace> --watch

# Describe a resource
kubectl describe pod <pod-name> -n <namespace>

# Check annotations (OneAgent injection)
kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations}'

# Rolling restart
kubectl rollout restart deployment -n <namespace>
kubectl rollout status deployment -n <namespace> --timeout=120s

# DynaKube
kubectl get dynakube -n dynatrace
kubectl describe dynakube -n dynatrace
```

## Quick reference — framework shell functions

```bash
# Cluster
startCluster · stopCluster · deleteCluster     # follow CLUSTER_ENGINE (k3d default)
installK9s

# Dynatrace
dynatraceDeployOperator
deployApplicationMonitoring     # AppOnly (recommended on k3d / Orbital)
deployDynatrace [mode]          # apponly | k8s-only | cloudnative
generateDynakube                # only writes .devcontainer/yaml/gen/dynakube.yaml
undeployDynakubes

# Apps
deployApp                       # list; deployApp <name> [-d]
deployTodoApp
registerApp <name> <ns> <svc> <port>

# Waiting
waitForPod <ns> <name>
waitForAllReadyPods <ns>

# Docs
installMkdocs · exposeMkdocs · deployGhdocs

# Output
printInfoSection "…" · printInfo "…" · printWarn "…" · printError "…"
```
