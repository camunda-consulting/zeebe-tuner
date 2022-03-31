package io.camunda.benchmark.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class KubeConfig {

	@Value("${kube.prefix}")
	public String kubePrefix;

	@Value("${kube.region}")
	public String kubeRegion;
}
