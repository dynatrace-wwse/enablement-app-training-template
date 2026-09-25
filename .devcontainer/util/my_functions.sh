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
#     command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkNodeReady"
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

# Create a TODO through the app's HTTP API, so a log line and a POST /todos
# trace reach Grail. The learner does this by hand in the app UI; this is the
# automation equivalent the LAB_SOLUTION and the nightly test need — neither can
# click a web page. The title is fixed: the DQL checks match the log text
# "Adding a new todo", so the hand-typed and the automated path look the same.
generateTodoTraffic() {
  local title="App Training Template"
  local url="http://localhost:${K3D_LB_HTTP_PORT:-80}"
  local host="todoapp.$(detectHostname)"
  printInfoSection "Creating a TODO so logs and traces reach Grail"

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
    printInfo "Created TODO \"$title\" — its log and trace should appear in Grail within ~2 min"
    return 0
  fi
  printError "Failed to create the TODO. Response: $resp"
  return 1
}
