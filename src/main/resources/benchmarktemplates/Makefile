# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform --version=${engine.helmChartVersion}

chartValues ?= camunda-values.yaml

# TODO configure through runner
include ../../../config.mk
#models ?= *.*mn
models ?= ${loadGeneratorStarter.processModel}.bpmn
benchmark ?= benchmark.yaml
#benchmark ?= benchmark-msg.yaml
#benchmark ?= benchmark-msg-with-jobs.yaml
payload ?= ${loadGeneratorStarter.payload}
scenario ?= msg-scenario.json
#scenario ?= msg-scenario-references.json

engineImage ?= ${engine.image}
gatewayReplicas ?= ${gateway.replicas}
gatewayPinning ?= ${gateway.pinning}

.PHONY: all
all: chart sync-image install-camunda chart-infos cpu-info.txt pods await-zeebe await-gateway deploy-models rebalance-leaders ${chaosTarget} benchmark await-benchmark
#all: chart sync-image install-camunda chart-infos cpu-info.txt pods await-zeebe deploy-models rebalance-leaders ${chaosTarget} await-elasticsearch await-webapps benchmark await-benchmark

.PHONY: clean
clean: clean-benchmark clean-job-deploy-models uninstall-camunda

# Set the timeout command based on the OS
# On MacOS `brew install coreutils` provides `gtimeout`
TIMEOUT_CMD := $(shell uname | grep -q 'Darwin' && echo 'gtimeout' || echo 'timeout')

ifeq ("$(OS)", "Windows_NT")
    root ?= $(CURDIR)/../../../../camunda-8-helm-profiles
else
    root ?= $(shell pwd)/../../../../camunda-8-helm-profiles
endif

include $(root)/include/camunda.mk
include $(root)/metrics/metrics.mk # for Grafana URL

.PHONY: sync-image
sync-image:
ifneq ("$(engineImage)", "camunda/zeebe")
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

.PHONY: generate-benchmark-configs # Generate benchmark configs with dynamic gateway IPs
generate-benchmark-configs:
ifeq ("$(gatewayPinning)", "TRUE")
	@echo "Generating benchmark configs with dynamic gateway IPs..."
	@GATEWAY_IPS=$$(kubectl get pods -l app.kubernetes.io/component=zeebe-gateway -n $(namespace) -o jsonpath='{.items[*].status.podIP}' | tr ' ' '\n' | sort); \
	IP_COUNT=$$(echo "$$GATEWAY_IPS" | wc -l); \
	if [ $$IP_COUNT -eq 0 ]; then \
		echo "No gateway IPs found!"; \
		exit 1; \
	fi; \
	i=0; \
	while [ $$i -lt $(gatewayReplicas) ]; do \
		IP_INDEX=$$((i % IP_COUNT)); \
		GATEWAY_IP=$$(echo "$$GATEWAY_IPS" | sed -n "$$((IP_INDEX + 1))p"); \
		export GATEWAY_IP=$$GATEWAY_IP; \
		export BENCHMARK_ID=$$i; \
		envsubst < benchmark-gateway-template.yaml > benchmark-gateway-$$i.yaml; \
		echo "Generated benchmark-gateway-$$i.yaml with IP $$GATEWAY_IP (round-robin $$IP_INDEX)"; \
		i=$$((i + 1)); \
	done
endif

.PHONY: benchmark
benchmark: namespace copy-models generate-benchmark-configs
ifeq ("$(gatewayPinning)", "TRUE")
	kubectl apply -f camunda-zeebe-gateway-headless.yaml                                   -n $(namespace)
endif
	kubectl create configmap payload      --from-file=$(payload)=models/$(payload)         -n $(namespace)
#	kubectl create configmap msg-scenario --from-file=msg-scenario.json=models/msg-scenario.json -n $(namespace)
	kubectl create configmap msg-scenario --from-file=msg-scenario.json=models/$(scenario) -n $(namespace)
ifeq ("$(gatewayPinning)", "TRUE")
	i=0; \
	while [ $$i -lt $(gatewayReplicas) ]; do \
		kubectl apply -f benchmark-gateway-$$i.yaml                                        -n $(namespace); \
		i=$$((i + 1)); \
	done
else
	kubectl apply -f $(benchmark)                                                          -n $(namespace)
#	kubectl expose deployment benchmark --type=ClusterIP   --name=benchmark-svc  --port=8088 --target-port=8088 -n $(namespace)
	kubectl apply -f benchmark-service-monitor.yaml                                        -n $(namespace)
endif
# TODO automatically switch/generate benchmark config

.PHONY: clean-benchmark
clean-benchmark:
ifeq ("$(gatewayPinning)", "TRUE")
	i=0; \
	while [ $$i -lt $(gatewayReplicas) ]; do \
		kubectl delete -f benchmark-gateway-$$i.yaml -n $(namespace); \
		i=$$((i + 1)); \
	done
else
	-kubectl delete service benchmark-svc             -n $(namespace)
	-kubectl delete -f $(benchmark)                   -n $(namespace)
endif
	-kubectl delete configmap payload                 -n $(namespace)
	-kubectl delete configmap msg-scenario            -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
ifeq ("$(gatewayPinning)", "TRUE")
	i=0; \
	while [ $$i -lt $(gatewayReplicas) ]; do \
		kubectl rollout status --watch statefulset/benchmark-gateway-$$i --timeout=900s -n $(namespace); \
		i=$$((i + 1)); \
	done
else
#	kubectl rollout status --watch deployment/benchmark --timeout=900s -n $(namespace)
	kubectl rollout status --watch statefulset/benchmark --timeout=900s -n $(namespace)
endif

.PHONY: logs-benchmark
logs-benchmark:
ifeq ("$(gatewayPinning)", "TRUE")
	selector=""; i=0; \
	while [ $$i -lt $(gatewayReplicas) ]; do \
	  if [ -z "$$selector" ]; then selector="benchmark-gateway-$$i"; else selector="$$selector,benchmark-gateway-$$i"; fi; \
	  i=$$((i+1)); \
	done; \
	kubectl logs -f -l "app in ($$selector)" -n $(namespace)
else
	kubectl logs -f -l app=benchmark -n $(namespace)
endif

.PHONY: logs-benchmark-timed
logs-benchmark-timed:
ifeq ("$(gatewayPinning)", "TRUE")
#	stern benchmark-gateway-[0-$(gatewayReplicas)] -n $(namespace)
	@$(TIMEOUT_CMD) ${loadGeneratorStarter.runDuration}s stern benchmark-gateway-[0-$(gatewayReplicas)] -n $(namespace) \
	|| { exit_code=$$?; [ $$exit_code -eq 124 ] && echo "${loadGeneratorStarter.runDuration}s timeout reached. Disconnecting from the bechmark logs." || exit $$exit_code; }
else
#	@$(TIMEOUT_CMD) 1200s kubectl logs -f -l "app in (benchmark-gateway-1,benchmark-gateway-2,benchmark-gateway-3,benchmark-gateway-4)" --max-log-requests=8 -n $(namespace) \
	|| { exit_code=$$?; [ $$exit_code -eq 124 ] && echo "1200s timeout reached. Disconnecting from the bechmark logs." || exit $$exit_code; }
	@$(TIMEOUT_CMD) ${loadGeneratorStarter.runDuration}s stern benchmark -n $(namespace) \
	|| { exit_code=$$?; [ $$exit_code -eq 124 ] && echo "${loadGeneratorStarter.runDuration}s timeout reached. Disconnecting from the bechmark logs." || exit $$exit_code; }
endif
