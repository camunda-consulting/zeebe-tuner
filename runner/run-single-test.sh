#!/bin/bash

testScenarioName=${1:-'example'}

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

cd ${testScenarioName}

# Start Zeebe
echo 'Starting Zeebe...'
#make zeebe await-zeebe
make

#make port-zeebe &
#sleep 3
#make bpmn
#kill [1]

echo 'Waiting for the Zeebe pods to be running...'
while [ "$(kubectl get statefulset ${testScenarioName}-zeebe -o json -n ${namespace} | jq -r '.status.readyReplicas == .status.replicas')" != "true" ]; do sleep 1; printf '.'; done
#while [ "$(kubectl get statefulset zeebe -o go-template --template='{{if eq .status.readyReplicas .status.replicas}}true{{end}}')" != "true" ]; do sleep 1; printf '.'; done
# produced: error: error executing template "{{if eq .status.readyReplicas .status.replicas}}true{{end}}": template: output:1:5: executing "output" at <eq .status.readyReplicas .status.replicas>: error calling eq: invalid type for comparison

# Start Starter
#echo 'Starting Starter and Worker...'
#make starter worker

## wait for the starter job to be finished
echo 'Waiting for completion of benchmark run...'
kubectl wait --for=condition=complete job/starter --timeout=1200s

#############
## Cleanup
echo 'Finished. Cleaning up now...'
make clean
kubectl delete namespace $namespace