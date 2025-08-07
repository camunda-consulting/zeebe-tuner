# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= camunda-values.yaml --version=${engine.helmChartVersion}

# TODO configure through runner
modelDir ?= ../../../models
#models ?= *.*mn
models ?= ${loadGeneratorStarter.processModel}.bpmn
benchmark ?= benchmark.yaml
#benchmark ?= benchmark-msg.yaml
#benchmark ?= benchmark-msg-with-jobs.yaml
payload ?= ${loadGeneratorStarter.payload}
scenario ?= msg-scenario.json
#scenario ?= msg-scenario-references.json

.PHONY: all
all: chart sync-image install-camunda chart-infos cpu-info.txt pods await-zeebe deploy-models rebalance-leaders ${chaosTarget} benchmark await-benchmark
#all: chart sync-image install-camunda chart-infos cpu-info.txt pods await-zeebe deploy-models rebalance-leaders ${chaosTarget} await-elasticsearch await-webapps benchmark await-benchmark

.PHONY: clean
clean: clean-benchmark clean-job-deploy-models uninstall-camunda

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../../camunda-8-helm-profiles
else
    root ?= $(shell pwd)/../../../../camunda-8-helm-profiles
endif

include $(root)/include/camunda.mk
include $(root)/metrics/metrics.mk # for Grafana URL

.PHONY: sync-image
sync-image:
  ifneq '${engine.image}' 'camunda/zeebe'
	docker manifest inspect gcr.io/camunda-researchanddevelopment/falko-zeebe:${engine.engineVersion} || docker buildx imagetools create --tag gcr.io/camunda-researchanddevelopment/falko-zeebe:${engine.engineVersion} gcr.io/zeebe-io/zeebe:${engine.engineVersion}
  endif

#: Deploy BPMN and DMN models using zbctl in a k8s job
deploy-models: copy-models job-deploy-models logs-job-deploy-models clean-job-deploy-models

.PHONY: copy-models
copy-models:
	mkdir -p models
	cp $(modelDir)/$(models) models
	cp $(modelDir)/$(payload) models
	cp $(modelDir)/$(scenario) models

#: Create k8s job to deploy BPMN and DMN models using zbctl
job-deploy-models:
	kubectl create configmap models --from-file=models                    -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)

cpu-info.txt:
	kubectl apply -f job-cpu-info.yaml                                    -n $(namespace)
	kubectl wait --for=condition=complete job/job-cpu-info --timeout=300s -n $(namespace)
	-kubectl logs job.batch/job-cpu-info                                  -n $(namespace) > cpu-info.txt
	-kubectl delete -f job-cpu-info.yaml                                  -n $(namespace)

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
	kubectl create configmap payload      --from-file=$(payload)=models/$(payload)       -n $(namespace)
#	kubectl create configmap msg-scenario --from-file=msg-scenario.json=models/msg-scenario.json -n $(namespace)
	kubectl create configmap msg-scenario --from-file=msg-scenario.json=models/$(scenario) -n $(namespace)
	kubectl apply -f $(benchmark)                                                          -n $(namespace)
	kubectl expose deployment benchmark --type=ClusterIP   --name=benchmark-svc  --port=8088 --target-port=8088
	kubectl apply -f benchmark-service-monitor.yaml -n $(namespace)
# TODO automatically switch/generate benchmark config

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f $(benchmark)        -n $(namespace)
	-kubectl delete configmap payload      -n $(namespace)
	-kubectl delete configmap msg-scenario -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

.PHONY: logs-benchmark
logs-benchmark:
	kubectl logs -f -l app=benchmark -n $(namespace)