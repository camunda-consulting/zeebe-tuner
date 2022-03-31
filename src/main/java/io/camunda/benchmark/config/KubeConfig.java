package io.camunda.benchmark.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class KubeConfig {

	@Value("${kube.namespace}")
	public String namespace;

	@Value("${kube.region}")
	public String kubeRegion;
}
