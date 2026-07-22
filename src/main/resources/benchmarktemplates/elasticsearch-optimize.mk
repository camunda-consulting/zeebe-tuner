# usage: make --makefile=elasticsearch-optimize.mk [target]

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda-optimize
# Helm release name
release ?= optimize
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= elasticsearch-optimize.yaml --version=${engine.helmChartVersion}

.PHONY: all
all: install-camunda pods await-elasticsearch await-optimize

.PHONY: clean
clean: uninstall-camunda

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../../camunda-8-helm-profiles
else
    root ?= $(shell pwd)/../../../../camunda-8-helm-profiles
endif

include $(root)/include/camunda.mk
include $(root)/metrics/metrics.mk # for Grafana URL

# Override camunda.mk's await-optimize: it assumes the Optimize deployment is named
# "$(release)-optimize", which holds when release=camunda (-> camunda-optimize) but not
# here, where release=optimize itself. Helm's fullname helper collapses "optimize-optimize"
# down to just "optimize" since the release name already contains the chart name.
.PHONY: await-optimize
await-optimize:
	kubectl rollout status --watch deployment/$(release) --timeout=900s -n $(namespace)
