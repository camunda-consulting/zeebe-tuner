namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

.PHONY: all
all: camunda await-zeebe deploy-models benchmark 

.PHONY: clean
clean: clean-benchmark clean-camunda

include ../../../../camunda-8-helm-profiles/include/camunda.mk

.PHONY: deploy-models
deploy-models:
	kubectl create configmap models --from-file=${loadGeneratorStarter.processModel}.bpmn   -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)
	kubectl delete -f zbctl-deploy-job.yaml             				  -n $(namespace)

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

