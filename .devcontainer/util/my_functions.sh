#!/bin/bash
# ======================================================================
#          ------- Custom Functions -------                            #
#  Your training-specific functions. This file is sourced into every   #
#  shell (Codespaces, Dev Containers and Orbital), so a function here  #
#  can be called from post-create.sh, from the terminal, from a        #
#  shell-verification `command:` and from a LAB_SOLUTION.              #
#                                                                      #
#  Rules:                                                              #
#  - Use `return`, never `exit` — this file is sourced, not run.       #
#  - Use printInfoSection / printInfo / printError from the framework. #
#  - Keep functions idempotent — they may be called many times.        #
#                                                                      #
#  See docs/02-automation.md and docs/04-interactive-blocks.md.        #
# ======================================================================

customFunction(){
  printInfoSection "This is a custom function that calculates 1 + 1"

  printInfo "1 + 1 = $(( 1 + 1 ))"
}

# ======================================================================
#   Step verification helpers (the enablement-kubernetes-101 pattern)
# ----------------------------------------------------------------------
#   A lesson's shell-verification block calls one of these:
#
#     command: "checkNodeReady"   # the platform sources the framework first
#     expect:
#       operator: exit-zero
#
#   A learner's click probes ONCE and answers immediately (return 0 = pass).
#   Automation (the nightly training-test, resume, "Run solution") exports
#   LAB_WAIT=1 first: the check then waits for the expected state before
#   probing, so verifying right after a solution does not race the rollout.
# ======================================================================

# Cluster node is Ready.
checkNodeReady() {
  if [ -n "${LAB_WAIT:-}" ]; then
    local i=0
    while [ "$i" -lt 18 ]; do
      [ "$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready')" -gt 0 ] && break
      i=$((i + 1)); printInfo "node not Ready yet ($i/18), waiting 5s"; sleep 5
    done
  fi
  if [ "$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready')" -gt 0 ]; then
    printInfo "Cluster node is Ready"; return 0
  fi
  printError "Cluster node is not Ready yet"; return 1
}

# TODO app pods are Running in the todoapp namespace.
checkTodoAppRunning() {
  [ -n "${LAB_WAIT:-}" ] && waitForAllReadyPods todoapp
  if [ "$(kubectl get pods -n todoapp --no-headers 2>/dev/null | grep -c Running)" -gt 0 ]; then
    printInfo "todoapp pods are Running"; return 0
  fi
  printError "todoapp pods are not Running yet — the environment may still be starting"; return 1
}

# Dynatrace Operator pod is Running.
checkOperatorReady() {
  [ -n "${LAB_WAIT:-}" ] && waitForPod dynatrace operator
  if kubectl get pods -n dynatrace --no-headers 2>/dev/null | grep -E 'operator' | grep -q Running; then
    printInfo "Dynatrace Operator pod is Running"; return 0
  fi
  printError "Dynatrace Operator is not running — run the install steps above, then check again"; return 1
}

# A DynaKube custom resource exists.
checkDynakube() {
  if [ -n "${LAB_WAIT:-}" ]; then
    local i=0
    while [ "$i" -lt 30 ]; do
      kubectl get dynakube -n dynatrace --no-headers 2>/dev/null | grep -q . && break
      i=$((i + 1)); printInfo "no DynaKube yet ($i/30), waiting 5s"; sleep 5
    done
  fi
  if kubectl get dynakube -n dynatrace --no-headers 2>/dev/null | grep -q .; then
    printInfo "DynaKube custom resource is present"; return 0
  fi
  printError "No DynaKube found in the dynatrace namespace — apply it, then check again"; return 1
}

# OneAgent was injected into the (restarted) todoapp pods.
checkOneAgentInjected() {
  if [ -n "${LAB_WAIT:-}" ]; then
    local i=0
    while [ "$i" -lt 24 ]; do
      kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\.dynatrace\.com/injected}' 2>/dev/null | tr ' ' '\n' | grep -q true && break
      i=$((i + 1)); printInfo "not injected yet ($i/24), waiting 10s"; sleep 10
    done
  fi
  if kubectl get pods -n todoapp -o jsonpath='{.items[*].metadata.annotations.oneagent\.dynatrace\.com/injected}' 2>/dev/null | tr ' ' '\n' | grep -q true; then
    printInfo "OneAgent is injected into the todoapp pods"; return 0
  fi
  printError "OneAgent is not injected — restart the todoapp deployment, wait for the rollout, then check again"; return 1
}

# ======================================================================
#   Solution / scenario helpers — call them from LAB_SOLUTION `commands:`
#   so the nightly test and resume can drive the step without a human.
# ======================================================================

# Restart the todoapp so the Dynatrace webhook injects OneAgent into it.
restartTodoApp() {
  printInfoSection "Restarting todoapp so OneAgent gets injected"
  kubectl rollout restart deployment -n todoapp
  kubectl rollout status deployment -n todoapp --timeout=180s
}

# Create a TODO through the app's HTTP API, so fresh todoapp log lines reach
# Grail. The learner may do this by hand in the app UI; this is the automation
# equivalent the LAB_SOLUTION and the nightly test use — neither can click a web
# page. The DQL check reads any log line from the learner's cluster, so it does
# not depend on this text; the title is fixed only to keep runs comparable.
generateTodoTraffic() {
  local title="App Training Template"
  local url="http://localhost:${K3D_LB_HTTP_PORT:-80}"
  local host="todoapp.$(detectHostname)"
  printInfoSection "Creating a TODO so fresh logs reach Grail"

  if [ -n "${LAB_WAIT:-}" ]; then
    local i=0
    while [ "$i" -lt 30 ]; do
      curl -sf -o /dev/null -H "Host: $host" "$url/todos" && break
      i=$((i + 1)); printInfo "app endpoint not ready ($i/30), waiting 5s"; sleep 5
    done
  fi
  if ! curl -sf -o /dev/null -H "Host: $host" "$url/todos"; then
    printError "todoapp HTTP endpoint not reachable yet — make sure the app is running, then try again"
    return 1
  fi

  local resp
  resp=$(curl -s -H "Host: $host" -X POST "$url/todos" -H "Content-Type: application/json" \
    -d "{\"title\":\"$title\",\"completed\":false}")
  if echo "$resp" | grep -q '"status":"ok"'; then
    printInfo "Created TODO \"$title\" — its log lines should appear in Grail within ~2 min"
    return 0
  fi
  printError "Failed to create the TODO. Response: $resp"
  return 1
}

# ======================================================================
#   Master-workshop helpers (How to Create Trainings) — all READ-ONLY.
#   None of them writes to the tenant or changes the cluster, so they
#   are safe on any tenant the app is installed in.
# ======================================================================

# dtctl and Monaco are on PATH. finalizePostCreation runs installDevTools in
# every framework repo, so a fresh environment has both without any line in
# post-create.sh. FRAMEWORK_DEVTOOLS=off is the one way to switch them off.
checkDevTools() {
  local rc=0
  if command -v dtctl >/dev/null 2>&1; then
    printInfo "dtctl:  $(dtctl version 2>/dev/null | head -1)"
  else
    printError "dtctl is not on PATH — installDevTools did not run or was switched off (FRAMEWORK_DEVTOOLS)"; rc=1
  fi
  if command -v monaco >/dev/null 2>&1; then
    printInfo "monaco: $(monaco version 2>/dev/null | head -1)"
  else
    printError "monaco is not on PATH — installDevTools did not run or was switched off (FRAMEWORK_DEVTOOLS)"; rc=1
  fi
  return $rc
}

# dtctl answers a read-only DQL query against the tenant this environment
# belongs to. installDevTools configures the read-only 'enablement' context
# only when the app delivered DT_DTCTL_TOKEN for this seat. The query reads
# Grail's bucket list: every tenant has buckets, and it needs no data in them.
# Never run `dtctl config view` here — it prints the resolved token.
checkDtctlQuery() {
  if ! command -v dtctl >/dev/null 2>&1; then
    printError "dtctl is not on PATH — run checkDevTools first"; return 1
  fi
  if [ -z "${DT_DTCTL_TOKEN:-}" ]; then
    printError "DT_DTCTL_TOKEN is not set: this seat was built without a dtctl token, so dtctl has no context"; return 1
  fi
  local out
  out=$(dtctl query -o json "fetch dt.system.buckets | summarize buckets = count()" 2>&1)
  if echo "$out" | grep -q '"buckets"'; then
    printInfo "dtctl reached the tenant: $(echo "$out" | tr -d ' \n' | grep -o '"buckets":"*[0-9]*' | head -1)"
    return 0
  fi
  printError "dtctl could not query the tenant: $(echo "$out" | head -3)"
  return 1
}

# The training app is published through the ingress: registerApp (called by
# deployTodoApp) created an Ingress in the app's namespace.
checkTodoAppIngress() {
  if [ "$(kubectl get ingress -n todoapp --no-headers 2>/dev/null | wc -l)" -gt 0 ]; then
    printInfo "todoapp is published through the ingress: $(kubectl get ingress -n todoapp --no-headers 2>/dev/null | awk '{print $3}' | head -1)"
    return 0
  fi
  printError "No Ingress in namespace todoapp — registerApp has not run (deployTodoApp in post-create.sh)"
  return 1
}

# How this training is delivered, derived the way Orbital derives it
# (orbital docs/concepts/training-delivery.md): shared infrastructure exists
# when .devcontainer/workshop-post-create.sh exists; .devcontainer/delivery.yaml
# wins over the index.md front matter; neither means self-service, tenancy any.
# Prints one line and returns 0 when the declaration is consistent.
describeTrainingDelivery() {
  local root="${REPO_PATH:-$PWD}"
  local shared="no" source="default (no delivery block)"
  [ -f "$root/.devcontainer/workshop-post-create.sh" ] && shared="yes"
  if [ -f "$root/.devcontainer/delivery.yaml" ]; then
    source="declared in .devcontainer/delivery.yaml"
  elif sed -n '1,/^---$/{/^delivery:/p}' "$root/docs/index.md" 2>/dev/null | grep -q delivery; then
    source="declared in docs/index.md front matter"
  fi
  printInfo "Delivery: $source; shared infrastructure: $shared"
  if [ "$shared" = "yes" ] && [ "$source" = "default (no delivery block)" ]; then
    printError "workshop-post-create.sh exists but nothing declares workshop-only + single: Orbital refuses shared mode"
    return 1
  fi
  echo "delivery=$source shared=$shared"
  return 0
}

# Scale the todoapp to N replicas and wait for the rollout. Idempotent: scaling
# to the current count is a no-op. Used by the "Blocks" module's LAB_SOLUTION,
# which sets its own `timeout:` because a rollout on a busy box can be slow.
scaleTodoApp() {
  local replicas="${1:-2}"
  printInfoSection "Scaling todoapp to $replicas replicas"
  kubectl scale deployment todoapp -n todoapp --replicas="$replicas" || return 1
  kubectl rollout status deployment todoapp -n todoapp --timeout=240s
}

# The todoapp has at least N ready replicas (default 2).
checkTodoAppReplicas() {
  local want="${1:-2}" ready
  if [ -n "${LAB_WAIT:-}" ]; then
    local i=0
    while [ "$i" -lt 24 ]; do
      ready=$(kubectl get deployment todoapp -n todoapp -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
      [ "${ready:-0}" -ge "$want" ] && break
      i=$((i + 1)); printInfo "todoapp has ${ready:-0}/$want ready replicas ($i/24), waiting 5s"; sleep 5
    done
  fi
  ready=$(kubectl get deployment todoapp -n todoapp -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${ready:-0}" -ge "$want" ]; then
    printInfo "todoapp has ${ready} ready replicas"; return 0
  fi
  printError "todoapp has ${ready:-0} ready replicas, expected at least $want — scale it: kubectl scale deployment todoapp -n todoapp --replicas=$want"
  return 1
}
