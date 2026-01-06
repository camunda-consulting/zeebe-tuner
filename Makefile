include config.mk

all:
	./gradlew bootRun

install:
	cd runner && ./run-all-tests.sh -o $(TESTRUNS_DONE_DIR)

teardown-current-run:
	cd runner && ./run-single-test-teardown.sh $$(realpath current/run) $(TESTRUNS_DONE_DIR)

clean:
	-cd runner/current/run && $(MAKE) clean
	-rm -r runner/testruns/*
	-rm -r --force runner/current

meld-benchmark:
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg.yaml
	meld src/main/resources/benchmarktemplates/benchmark-msg.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
# TODO meld ../c8b/src/main/resources/application.properties src/main/resources/benchmarktemplates/benchmark.yaml

meld-current-run:
	meld src/main/resources/benchmarktemplates runner/current/run

meld-camunda-values.yaml:
	meld src/main/resources/benchmarktemplates/camunda-values.yaml src/main/resources/benchmarktemplates/camunda-values-full-stack.yaml
	meld ../camunda-8-helm-profiles/development/camunda-values-2.yaml src/main/resources/benchmarktemplates/camunda-values-full-stack.yaml
