echo "###############################################"
echo "Running test for config: ${testCaseName}"
#
namespace="${namespace}"
#
kubectl create namespace $namespace
kubens $namespace
#
# Start Zeebe
echo 'Starting Zeebe...'
make zeebe
#
echo 'Waiting for the Zeebe pods to be running...'
while [ "$(kubectl get statefulset ${namespace}-zeebe -o json -n ${namespace} | jq -r '.status.readyReplicas == .status.replicas')" != "true" ]; do sleep 1; printf '.'; done
#
make camunda-cloud-benchmark
#
make url-grafana