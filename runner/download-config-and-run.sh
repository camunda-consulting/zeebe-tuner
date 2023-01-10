#!/bin/bash
set -euo pipefail

# retrieve machine types from K8s
machineType=$(kubectl get node -o json | jq -r '.items[0].metadata.labels."beta.kubernetes.io/instance-type"')
echo "Machine type: ${machineType}"

# download configs from Google Sheet
java -DmachineType=$machineType -jar sheets-exporter.jar

# and run all tests
./run-all-tests.sh