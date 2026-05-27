#!/bin/bash
# ======================================================================
#          ------- Custom Functions -------                            #
#  Add training-specific functions here. They are sourced into every   #
#  terminal session automatically (Codespaces and Orbital).            #
#                                                                       #
#  Rules:                                                               #
#    - Use `return`, never `exit` — this file is sourced, not run.     #
#    - Use `printInfoSection` and `printInfo` from the framework.       #
#    - Keep functions idempotent — they may be called multiple times.   #
#                                                                       #
#  See docs/AUTHORING.md#custom-functions for full docs.               #
# ======================================================================


# -----------------------------------------------------------------------
# Example: simple calculation (ships with the template — keep as pattern)
# -----------------------------------------------------------------------
customFunction(){
  printInfoSection "This is a custom function that calculates 1 + 1"
  printInfo "1 + 1 = $(( 1 + 1 ))"
}


# -----------------------------------------------------------------------
# Example: fault injection — scale a deployment to 0 replicas
# Copy and adapt for your training scenario.
# -----------------------------------------------------------------------
# injectFault(){
#   printInfoSection "Injecting a synthetic failure into todoapp"
#   kubectl scale deployment todoapp -n todoapp --replicas=0
#   printInfo "todoapp scaled to 0 replicas — check your Dynatrace dashboard"
# }


# -----------------------------------------------------------------------
# Example: restore normal state after fault injection
# -----------------------------------------------------------------------
# restoreApp(){
#   printInfoSection "Restoring todoapp to normal"
#   kubectl scale deployment todoapp -n todoapp --replicas=1
#   kubectl rollout status deployment/todoapp -n todoapp --timeout=60s
#   printInfo "todoapp restored"
# }


# -----------------------------------------------------------------------
# Example: training scenario setup — call from STEP_SETUP or post-create
# -----------------------------------------------------------------------
# mySetupFunction(){
#   printInfoSection "Setting up training scenario"
#   # add your setup logic here
#   printInfo "Setup complete"
# }


# -----------------------------------------------------------------------
# Example: validation helper — returns 0 (pass) or 1 (fail)
# Use in shell-verification command: myValidationHelper && echo 1 || echo 0
# -----------------------------------------------------------------------
# myValidationHelper(){
#   local count
#   count=$(kubectl get pods -n todoapp --no-headers 2>/dev/null | grep -c Running)
#   if [[ "$count" -gt 0 ]]; then
#     printInfo "Validation passed: $count Running pods found"
#     return 0
#   else
#     printInfo "Validation failed: no Running pods in todoapp"
#     return 1
#   fi
# }
