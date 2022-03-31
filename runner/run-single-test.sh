#!/bin/bash

testScenarioName=${1:-'example'}

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

source ../.env
echo "GCP project:  ${GCP_PROJECT_NAME}"
echo "Image prefix: ${IMAGE_PREFIX}"
echo "Image tag:    ${IMAGE_TAG}"

############
# Generation

# dummy hard coded for test-1
echo 'Generating Kubernetes configs'
mkdir testruns/${testScenarioName}
helm template template-chart \
    --output-dir testruns/${testScenarioName} \
    --values testruns/${testScenarioName}.yaml \
    --set testScenarioName=${testScenarioName} \
    --set gcpProjectName=${GCP_PROJECT_NAME} \
    --set imagePrefix=${IMAGE_PREFIX} \
    --set imageTag=${IMAGE_TAG}

cd testruns/${testScenarioName}/chart/templates
echo "$(tail -n +3 Makefile)" > Makefile

############
# Run test-1

namespace=${testScenarioName}
kubectl create namespace $namespace
kubens $namespace


# Start Zeebe
echo 'Starting Zeebe...'
make zeebe

echo 'Waiting for the Zeebe pods to be running...'
while [ "$(kubectl get statefulset ${testScenarioName}-zeebe -o json -n ${namespace} | jq -r '.status.readyReplicas == .status.replicas')" != "true" ]; do sleep 1; printf '.'; done
#while [ "$(kubectl get statefulset zeebe -o go-template --template='{{if eq .status.readyReplicas .status.replicas}}true{{end}}')" != "true" ]; do sleep 1; printf '.'; done
# produced: error: error executing template "{{if eq .status.readyReplicas .status.replicas}}true{{end}}": template: output:1:5: executing "output" at <eq .status.readyReplicas .status.replicas>: error calling eq: invalid type for comparison

# Start Starter
echo 'Starting Starter and Worker...'
make starter worker

## wait for the starter job to be finished
echo 'Waiting for completion of benchmark run...'
kubectl wait --for=condition=complete job/starter --timeout=1200s

#############
## Cleanup
echo 'Finished. Cleaning up now...'
make clean
kubectl delete namespace $namespace