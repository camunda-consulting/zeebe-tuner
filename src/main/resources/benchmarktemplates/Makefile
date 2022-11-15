namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
chartValues ?= "camunda-values.yaml"

.PHONY: all
all: camunda await-zeebe deploy-models rebalance-partitions ${chaosTarget} benchmark 

.PHONY: clean
clean: clean-benchmark clean-camunda

include ../../../../camunda-8-helm-profiles/include/camunda.mk

.PHONY: deploy-models
deploy-models:
	kubectl create configmap models --from-file=singleProcess.bpmn   -n $(namespace)
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

.PHONY: rebalance-partitions
rebalance-partitions:
	kubectl port-forward --namespace camunda $$(kubectl get pod --namespace camunda --selector="app=camunda-platform,app.kubernetes.io/component=zeebe-gateway,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=zeebe-gateway,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') 5433:9600 > pid.txt &
	curl -X POST http://localhost:5433/actuator/rebalance/
	sleep 10
	kill $$(ps aux | grep 'kubectl' | awk '{print $$1}')

.PHONY: benchmark
benchmark: namespace
	kubectl create configmap payload --from-file=payload.json -n $(namespace)
	kubectl apply -f benchmark.yaml                           -n $(namespace)

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f benchmark.yaml -n $(namespace)
	-kubectl delete configmap payload -n $(namespace)

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

