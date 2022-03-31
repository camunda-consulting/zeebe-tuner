cd eks
make
cd ..
make zeebe
make watch-zeebe # until running
make port-zeebe
zbctl --insecure status # check brokers/leaders/health
make bpmn
make camunda-cloud-benchmark
make open-grafana 