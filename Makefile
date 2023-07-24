all:
	./gradlew bootRun

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