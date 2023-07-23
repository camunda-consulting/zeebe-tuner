all:
	./gradlew bootRun

meld:
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
	meld src/main/resources/benchmarktemplates/benchmark.yaml src/main/resources/benchmarktemplates/benchmark-msg.yaml
	meld src/main/resources/benchmarktemplates/benchmark-msg.yaml src/main/resources/benchmarktemplates/benchmark-msg-with-jobs.yaml
# TODO meld ../c8b/src/main/resources/application.properties src/main/resources/benchmarktemplates/benchmark.yaml