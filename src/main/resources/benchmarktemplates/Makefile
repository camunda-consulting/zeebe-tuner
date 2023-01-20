# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= "camunda-values.yaml"

.PHONY: all
all: sync-image camunda await-zeebe deploy-models rebalance-leaders ${chaosTarget} benchmark 

.PHONY: clean
clean: clean-benchmark clean-camunda

include ../../../../camunda-8-helm-profiles/include/camunda.mk

.PHONY: sync-image
sync-image:
	docker buildx imagetools create --tag gcr.io/camunda-researchanddevelopment/falko-zeebe:${engine.engineVersion} gcr.io/zeebe-io/zeebe:${engine.engineVersion}

.PHONY: deploy-models
deploy-models:
	kubectl create configmap models --from-file=${loadGeneratorStarter.processModel}.bpmn   -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)
	kubectl delete -f zbctl-deploy-job.yaml             				  -n $(namespace)

.PHONY: deploy-chaos-gateway
deploy-chaos-gateway:
	kubectl apply -f chaos-network-gateway.yaml -n $(namespace)	

.PHONY: deploy-chaos-broker
deploy-chaos-broker:
	kubectl apply -f chaos-network-brokers.yaml -n $(namespace)	

.PHONY: benchmark
benchmark: namespace
	kubectl create configmap payload      --from-file=payload.json      -n $(namespace)
	kubectl create configmap msg-scenario --from-file=msg-scenario.json -n $(namespace)
	kubectl apply -f benchmark.yaml                                     -n $(namespace)

# Getting url for grafana is vendor specific
.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -n default -o 'custom-columns=ip:status.loadBalancer.ingress[0].ip' | tail -n 1`/d/IDjA72vVz2/zeebe-low-latency?var-namespace=$(namespace)"

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f benchmark.yaml      -n $(namespace)
	-kubectl delete configmap payload      -n $(namespace)
	-kubectl delete configmap msg-scenario -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

