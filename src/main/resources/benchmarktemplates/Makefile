# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= "camunda-values.yaml"

# TODO configure through runner
models ?= ../../../models

.PHONY: all
all: sync-image camunda await-zeebe deploy-models rebalance-leaders ${chaosTarget} benchmark 

.PHONY: clean
clean: clean-benchmark clean-camunda

include ../../../../camunda-8-helm-profiles/include/camunda.mk

.PHONY: sync-image
sync-image:
  ifneq '${engine.image}' 'camunda/zeebe'
	docker buildx imagetools create --tag gcr.io/camunda-researchanddevelopment/falko-zeebe:${engine.engineVersion} gcr.io/zeebe-io/zeebe:${engine.engineVersion}
  endif

#: Deploy BPMN and DMN models using zbctl in a k8s job
deploy-models: copy-models job-deploy-models logs-job-deploy-models clean-job-deploy-models

.PHONY: copy-models
copy-models:
	mkdir -p models && cp $(models)/* models

#: Create k8s job to deploy BPMN and DMN models using zbctl
job-deploy-models:
	kubectl create configmap models --from-file=models                    -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)

#: Show output of k8s job to deploy BPMN and DMN models using zbctl
logs-job-deploy-models:
	-kubectl logs job.batch/zbctl-deploy -n $(namespace)

#: Delete k8s job to deploy BPMN and DMN models using zbctl
clean-job-deploy-models:
	-kubectl delete configmap models         -n $(namespace)
	-kubectl delete -f zbctl-deploy-job.yaml -n $(namespace)

.PHONY: deploy-chaos-gateway
deploy-chaos-gateway:
	kubectl apply -f chaos-network-gateway.yaml -n $(namespace)	

.PHONY: deploy-chaos-broker
deploy-chaos-broker:
	kubectl apply -f chaos-network-brokers.yaml -n $(namespace)	

.PHONY: benchmark
benchmark: namespace copy-models
	kubectl create configmap payload      --from-file=payload.json=models/payload.json           -n $(namespace)
	kubectl create configmap msg-scenario --from-file=msg-scenario.json=models/msg-scenario.json -n $(namespace)
	kubectl apply -f benchmark-msg-with-jobs.yaml                                                -n $(namespace)
# TODO automatically switch/generate benchmark config

# Getting url for grafana is vendor specific
.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -n default -o 'custom-columns=ip:status.loadBalancer.ingress[0].ip' | tail -n 1`/d/zeebe-dashboard/zeebe?var-namespace=$(namespace)"

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f benchmark.yaml      -n $(namespace)
	-kubectl delete configmap payload      -n $(namespace)
	-kubectl delete configmap msg-scenario -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

.PHONY: logs-benchmark
logs-benchmark:
	kubectl logs -f -l app=benchmark -n $(namespace)
