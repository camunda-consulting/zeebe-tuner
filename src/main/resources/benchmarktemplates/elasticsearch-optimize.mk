# usage: make --makefile=elasticsearch-optimize.mk [target]

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= optimize
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= elasticsearch-optimize.yaml --version=${engine.helmChartVersion}

.PHONY: all
all: install-camunda pods await-elasticsearch

.PHONY: clean
clean: uninstall-camunda

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../../camunda-8-helm-profiles
else
    root ?= $(shell pwd)/../../../../camunda-8-helm-profiles
endif

include $(root)/include/camunda.mk
include $(root)/metrics/metrics.mk # for Grafana URL