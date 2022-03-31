#!/bin/bash
set -euxo pipefail

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

kubectl apply -f grafana-secret.yml
until helm install metrics prometheus-community/kube-prometheus-stack --atomic -f prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false | grep -m 1 "kube-prometheus-stack has been installed."
do
	printf .
	sleep 1
done

kubectl apply -f grafana-load-balancer.yml