include config.mk

# Namespace and Helm release that the generated test runs install into. These mirror the
# defaults in src/main/resources/benchmarktemplates/Makefile so that the cluster can still be
# torn down when no test run is currently checked out. Override them if kube.namespace in
# application.yml points somewhere else.
namespace ?= camunda
release ?= camunda

all:
	./gradlew --configuration-cache bootRun

install:
	cd runner && ./run-all-tests.sh -o $(TESTRUNS_DONE_DIR)

teardown-current-run:
	cd runner && ./run-single-test-teardown.sh $$(realpath current/run) $(TESTRUNS_DONE_DIR)

runner/current/run:
	$(MAKE) -C runner current/run

clean: clean-current-run
	-$(MAKE) clean -C runner
	-rm -r runner/testruns/*

# runner/current/run is a symlink into runner/testruns/<id> and it becomes dangling as soon as
# that run is archived into TESTRUNS_DONE_DIR. Recursing into it then fails, and because the
# recipe was prefixed with '-' the failure was silent: `make clean` reported success while
# leaving the Helm release, its PVCs and the benchmark deployment running. The next
# `make all install` then failed in install-camunda, because `helm upgrade` cannot change the
# immutable StatefulSet fields of an already-installed release:
#   StatefulSet.apps "camunda-zeebe" is invalid: spec: Forbidden: updates to statefulset spec
#   for fields other than 'replicas', ... are forbidden
# Fall back to a teardown that does not depend on the symlink resolving. The check runs in the
# shell rather than via $(wildcard ...) so it reflects the state at recipe time.
clean-current-run:
	@if [ -f runner/current/run/Makefile ]; then \
		$(MAKE) clean -C runner/current/run; \
	else \
		echo "runner/current/run is missing or dangling - falling back to clean-cluster"; \
		$(MAKE) clean-cluster; \
	fi

#: Uninstall Camunda and the benchmark without requiring a generated test run to be present
clean-cluster:
	-helm --namespace $(namespace) uninstall $(release)
	-kubectl delete --namespace $(namespace) pvc -l app.kubernetes.io/instance=$(release)
	-kubectl delete --namespace $(namespace) deployment benchmark --ignore-not-found
	-kubectl delete --namespace $(namespace) service benchmark-svc --ignore-not-found
	-kubectl delete --namespace $(namespace) configmap payload msg-scenario --ignore-not-found

meld-benchmark:
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg.yaml
	meld src/main/resources/benchmarktemplates/benchmark-msg.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
# TODO meld ../c8b/src/main/resources/application.properties src/main/resources/benchmarktemplates/benchmark.yaml

meld-current-run: runner/current/run
	meld src/main/resources/benchmarktemplates runner/current/run

meld-last-run: runner/current/run
	meld runner/last/run runner/current/run

meld-camunda-values.yaml:
	meld src/main/resources/benchmarktemplates/camunda-values.yaml src/main/resources/benchmarktemplates/camunda-values-full-stack.yaml
	meld ../camunda-8-helm-profiles/development/camunda-values-2.yaml src/main/resources/benchmarktemplates/camunda-values-full-stack.yaml
