package io.camunda.benchmark.aws;

import java.io.IOException;
import java.util.Map;

import org.springframework.stereotype.Service;

import io.camunda.benchmark.utils.ProcessUtils;

@Service
public class EksService {

	public void createEksCluster() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("eksctl create cluster -f target/eks/eksctl-config.yaml");
		ProcessUtils.execBlocking("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts");
		ProcessUtils.execBlocking("helm repo add stable https://charts.helm.sh/stable");
		ProcessUtils.execBlocking("helm repo update");
		ProcessUtils.execBlocking("kubectl apply -f target/eks/grafana-secret.yml");
		ProcessUtils.execBlocking("helm install metrics prometheus-community/kube-prometheus-stack --atomic -f target/eks/prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false");
			
			/*until  | grep -m 1 "kube-prometheus-stack has been installed."
			do
				printf .
				sleep 1
			done*/

		ProcessUtils.execBlocking("kubectl apply -f target/eks/grafana-load-balancer.yml");
		//expose grafana
		ProcessUtils.execBlocking("kubectl port-forward svc/metrics-grafana-loadbalancer 8080:80 -n default");
		//expose prometheus
		ProcessUtils.execBlocking("kubectl port-forward svc/metrics-kube-prometheus-st-prometheus 9090:9090 -n default");
	}
	
	public String getUrlGrafana() throws IOException, InterruptedException {
		Map<String, Object> result = ProcessUtils.execBlocking("kubectl get svc metrics-grafana-loadbalancer -o 'custom-columns=ip:status.loadBalancer.ingress[0].hostname'");
		//TODO:build URL
		return (String) result.get("output");
	}
	
	public void cleanEksCluster() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("kubectl delete -n default -f target/eks/grafana-load-balancer.yml");
		ProcessUtils.execBlocking("helm --namespace default uninstall metrics");
		ProcessUtils.execBlocking("kubectl delete -n default -f target/eks/grafana-secret.yml");
		ProcessUtils.execBlocking("kubectl delete -n default pvc -l app.kubernetes.io/name=prometheus");
		ProcessUtils.execBlocking("kubectl delete -n default pvc -l app.kubernetes.io/name=grafana");
		//ProcessUtils.execBlocking("kubectl delete pvc --all");
		ProcessUtils.execBlocking("eksctl delete cluster -f target/eks/eksctl-config.yaml --wait");
	}
}
