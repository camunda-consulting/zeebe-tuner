cd eks
make
cd ..
make zeebe await-zeebe port-zeebe
zbctl --insecure status # optional check of brokers/leaders/health
make bpmn camunda-cloud-benchmark
make open-grafana
