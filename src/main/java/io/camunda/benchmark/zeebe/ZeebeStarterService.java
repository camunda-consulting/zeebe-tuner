package io.camunda.benchmark.zeebe;

import java.io.IOException;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import io.camunda.benchmark.config.KubeConfig;
import io.camunda.benchmark.utils.ProcessUtils;

@Service
public class ZeebeStarterService {

	@Autowired
	private KubeConfig kubeConfig;
	
	public void buildZeebe() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("kubectl create namespace "+kubeConfig.namespace);
		ProcessUtils.execBlocking("helm repo add camunda-cloud https://helm.camunda.io");
		ProcessUtils.execBlocking("helm repo update camunda-cloud");
		ProcessUtils.execBlocking("helm search repo camunda-cloud/ccsm-helm");
		ProcessUtils.execBlocking("helm install --namespace "+kubeConfig.namespace+" "+kubeConfig.namespace+" camunda-cloud/ccsm-helm -f testruns/zeebe-values.yaml --skip-crds");
	}
	
	public boolean watchZeebe() throws IOException, InterruptedException {
		Map<String, Object> result = ProcessUtils.execBlocking("kubectl get pods -w -n "+kubeConfig.namespace+" -l app.kubernetes.io/name=camunda-platform");
		String output = (String) result.get("output");
		//TODO:check output
		if (output.indexOf("blop")>0) {
			Thread.sleep(1500);
			return watchZeebe();
		}
		return true;
	}
	
	public void exposeZeebe() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("kubectl port-forward svc/"+kubeConfig.namespace+"-zeebe-gateway 26500:26500 -n "+kubeConfig.namespace);
	}
	
	public void deployProcess() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("zbctl --insecure deploy testruns/*.bpmn");
	}
	
	public void camundaCloudBenchmark() throws IOException, InterruptedException {
		ProcessUtils.execBlocking("kubectl apply -n "+kubeConfig.namespace+" -f testruns/camunda-cloud-benchmark.yaml");
	}
		
}
