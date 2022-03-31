clustername ?= ${namespace}-cluster

.PHONY: all
all: eks-cluster urls

.PHONY: eks-cluster
eks-cluster:
	eksctl create cluster -f eksctl-config.yaml
	bash setup-cluster.sh $(clustername) ${region}

.PHONY: clean
clean: clean-eks-cluster

.PHONY: clean-eks-cluster
clean-eks-cluster:
	-kubectl delete -n default -f grafana-load-balancer.yml
	-helm --namespace default uninstall metrics
	-kubectl delete -n default -f grafana-secret.yml
	-kubectl delete -n default pvc -l app.kubernetes.io/name=prometheus
	-kubectl delete -n default pvc -l app.kubernetes.io/name=grafana
#	-kubectl delete pvc --all
	eksctl delete cluster -f eksctl-config.yaml --wait

.PHONY: urls
urls:
	@echo "CloudFormation: https://${region}.console.aws.amazon.com/cloudformation/home?region=${region}#/stacks?filteringStatus=active&filteringText=eksctl-$(clustername)-cluster&viewNested=true&hideStacks=false&stackId="
	@echo "EKS: https://${region}.console.aws.amazon.com/eks/home?region=${region}#/clusters"

.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -o 'custom-columns=ip:status.loadBalancer.ingress[0].hostname' | tail -n 1`/d/I4lo7_EZk/zeebe"

.PHONY: port-grafana
port-grafana:
	kubectl port-forward svc/metrics-grafana-loadbalancer 8080:80 -n default

.PHONY: port-prometheus
port-prometheus:
	kubectl port-forward svc/metrics-kube-prometheus-st-prometheus 9090:9090 -n default

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath={..hostname})/d/I4lo7_EZk/zeebe &

.PHONY: open-cloudformation
open-cloudformation:
	xdg-open https://${region}.console.aws.amazon.com/cloudformation/home?region=${region}#/stacks?filteringStatus=active&filteringText=eksctl-$(clustername)-cluster&viewNested=true&hideStacks=false&stackId= &

.PHONY: open-eks
open-eks:
	xdg-open https://${region}.console.aws.amazon.com/eks/home?region=${region}#/clusters