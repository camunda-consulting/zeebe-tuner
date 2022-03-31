release ?= ${namespace}
chart ?= camunda-cloud/ccsm-helm

.PHONY: all
all: zeebe camunda-cloud-benchmark

.PHONY: zeebe
zeebe:
	-kubectl create namespace ${namespace}
	helm repo add camunda-cloud https://helm.camunda.io
	helm repo update camunda-cloud
	helm search repo $(chart)
	helm install --namespace ${namespace} $(release) $(chart) -f zeebe-values.yaml --skip-crds

# Generates templates from the zeebe helm charts, useful to make some more specific changes which are not doable by the values file.
# To apply the templates use k apply -f ccsm-helm/templates/
.PHONY: template
template:
	helm template $(release) $(chart) -f zeebe-values.yaml --skip-crds --output-dir .

.PHONY: update
update:
	helm upgrade --namespace ${namespace} $(release) $(chart) -f zeebe-values.yaml

.PHONY: starter
starter:
	kubectl apply -n ${namespace} -f starter.yaml

.PHONY: worker
worker:
	kubectl apply -n ${namespace} -f worker.yaml

.PHONY: camunda-cloud-benchmark
camunda-cloud-benchmark:
	kubectl apply -n ${namespace} -f camunda-cloud-benchmark.yaml

.PHONY: clean
clean: clean-starter clean-worker clean-camunda-cloud-benchmark clean-zeebe

.PHONY: clean-zeebe
clean-zeebe:
	-helm --namespace ${namespace} uninstall $(release)
	-kubectl delete -n ${namespace} pvc -l app.kubernetes.io/instance=${namespace}
	-kubectl delete -n ${namespace} pvc -l app=elasticsearch-master

.PHONY: clean-starter
clean-starter:
	-kubectl delete -n ${namespace} -f starter.yaml

.PHONY: clean-worker
clean-worker:
	-kubectl delete -n ${namespace} -f worker.yaml

.PHONY: clean-camunda-cloud-benchmark
clean-camunda-cloud-benchmark:
	-kubectl delete -n ${namespace} -f camunda-cloud-benchmark.yaml

.PHONY: logs
logs:
	kubectl logs -f -n ${namespace} -l app.kubernetes.io/name=zeebe

.PHONY: logs-starter
logs-starter:
	kubectl logs -f -n ${namespace} -l app=starter

.PHONY: logs-worker
logs-worker:
	kubectl logs -f -n ${namespace} -l app=worker --max-log-requests=$(shell grep replicas worker.yaml | cut -d ' ' -f 4)

.PHONY: watch-zeebe
watch-zeebe:
	kubectl get pods -w -n ${namespace} -l app.kubernetes.io/name=zeebe

.PHONY: watch-starter
watch-starter:
	kubectl get pods -w -n ${namespace} -l app=starter

.PHONY: watch-worker
watch-worker:
	kubectl get pods -w -n ${namespace} -l app=worker

.PHONY: port-zeebe
port-zeebe:
	kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 -n ${namespace}

.PHONY: bpmn
bpmn:
	zbctl --insecure deploy *.bpmn

.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -n default -o 'custom-columns=ip:status.loadBalancer.ingress[0].hostname' | tail -n 1`/d/I4lo7_EZk/zeebe?var-namespace=${namespace}"

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath={..hostname})/d/I4lo7_EZk/zeebe?var-namespace=${namespace} &