# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform --version=${engine.helmChartVersion}

chartValues ?= camunda-values.yaml

# TODO configure through runner
include ../../../config.mk

ifeq (${loadGeneratorStarter.deployMultipleModels},TRUE)
models ?= *.*mn
else
models ?= ${loadGeneratorStarter.processModel}.bpmn
endif

# switch between deploying models using zbctl in a k8s job or locally by port-forwarding to the Zeebe Gateway in k8s
ifeq (${loadGeneratorStarter.deployWithLocalZbctl},TRUE)
deployModels ?= deploy-models-zbctl-local
else
deployModels ?= deploy-models
endif

benchmark ?= benchmark.yaml
#benchmark ?= benchmark-msg.yaml
#benchmark ?= benchmark-msg-with-jobs.yaml
payload ?= ${loadGeneratorStarter.payload}
scenario ?= msg-scenario.json
#scenario ?= msg-scenario-references.json

# add Make target to wait for Elasticsearch to be ready if enabled, otherwise leave it empty
ifeq (${elasticSearch.enabled},TRUE)
awaitElasticsearch ?= await-elasticsearch
else
awaitElasticsearch ?=
endif

.PHONY: all
all: chart sync-image install-camunda chart-infos cpu-info.txt pods await-zeebe ${deployModels} rebalance-leaders ${chaosTarget} ${awaitElasticsearch} benchmark await-benchmark
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

.PHONY: deploy-models-zbctl-local # Deploy an unlimited number of BPMN and DMN models using zbctl locally by port-forwarding to the Zeebe Gateway in k8s
deploy-models-zbctl-local: copy-models
	kubectl port-forward svc/$(release)-zeebe-gateway 26500:grpc -n $(namespace) &
	sleep 10
	find models -iname '$(models)' -type f -print0 | xargs -0 -I{} sh -c 'echo "Deploying $$1"; zbctl --insecure deploy resource "$$1" || exit 255' sh {}
	kill $$(ps | grep 'kubectl' | awk '{print $$1}')

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
	-kubectl delete service benchmark-svc  -n $(namespace)
	-kubectl delete -f $(benchmark)        -n $(namespace)
	-kubectl delete configmap payload      -n $(namespace)
	-kubectl delete configmap msg-scenario -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

.PHONY: logs-benchmark
logs-benchmark:
	kubectl logs -f -l app=benchmark -n $(namespace)
