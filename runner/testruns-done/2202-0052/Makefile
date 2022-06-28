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
	kubectl create configmap models --from-file=EightTasks.bpmn   -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)
	kubectl delete -f zbctl-deploy-job.yaml             				  -n $(namespace)

.PHONY: clean-deploy-models
clean-deploy-models:
	kubectl delete -f zbctl-deploy-job.yaml             				  -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)

.PHONY: benchmark
benchmark:
	kubectl apply -n $(namespace) -f benchmark.yaml

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -n $(namespace) -f benchmark.yaml

.PHONY: await-benchmark
await-benchmark:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app=benchmark --timeout=900s

