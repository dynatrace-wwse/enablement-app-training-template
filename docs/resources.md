# Resources

## Authoring references

- [AUTHORING.md](AUTHORING.md) — complete schema reference for all interactive block types
- [ORBITAL_AND_APP.md](ORBITAL_AND_APP.md) — runtime architecture: how Orbital and the Dynatrace app connect
- [REFERENCE_KUBERNETES_101.md](REFERENCE_KUBERNETES_101.md) — full inventory of interactive mechanisms from the reference training

## Reference training

- [enablement-kubernetes-101](https://github.com/dynatrace-wwse/enablement-kubernetes-101) — canonical reference training

## Framework documentation

- [Codespaces Framework docs](https://dynatrace-wwse.github.io/codespaces-framework) — full framework reference: cache, functions.sh, sync CLI, local Docker mode, integration tests

## MkDocs Material

- [MkDocs Material reference](https://squidfunk.github.io/mkdocs-material/reference/) — admonitions, code blocks, grids, icons
- [MkDocs snippets](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#snippets) — `--8<--` include syntax

## Dynatrace

- [DQL reference](https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-query-language) — full DQL syntax
- [Dynatrace Operator for Kubernetes](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/deployment)
- [DynaKube custom resource reference](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/reference/dynakube)
- [Dynatrace App Toolkit](https://dt-url.net/app-toolkit) — App IDs for `dt-app` deep links

## Orbital Operations server

- URL: `https://autonomous-enablements.whydevslovedynatrace.com`
- Contact: Orbital administrator (Slack: #enablement-orbital)

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
# Print section header
printInfoSection "Section heading"

# Print info line
printInfo "Info message"

# Deploy standard apps
deployTodoApp
deployAstroshop

# Dynatrace operator
dynatraceEvalReadSaveCredentials
generateDynakube
dynatraceDeployOperator

# Docs
installMkdocs
exposeMkdocs
deployGhdocs

# Cluster
startK3dCluster
installK9s

# Codespace management
deleteCodespace
```
