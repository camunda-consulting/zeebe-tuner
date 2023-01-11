package io.camunda.benchmark.service;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.io.IOUtils;
import org.apache.commons.text.StringSubstitutor;
import org.springframework.stereotype.Service;

import io.camunda.benchmark.utils.FileUtils;


@Service
public class TemplatingService {
	
	private static final String YAML_FOLDER = "benchmarktemplates";
	
	public void buildConfFiles(Map<String, String> inputs) throws IOException, GeneralSecurityException {
		StringSubstitutor sub = new StringSubstitutor(inputs);
		
		ClassLoader loader = Thread.currentThread().getContextClassLoader();
		URL yamlFilesUrl = loader.getResource(YAML_FOLDER);
		String yamlFilesPath = yamlFilesUrl.getPath();

		Map<String, String> files = getSourcesAndTarget(new File(yamlFilesPath), inputs.get("testCaseName"));
		for(Map.Entry<String, String> file : files.entrySet()) {
			String template = IOUtils.toString(this.getClass().getClassLoader().getResourceAsStream(file.getKey()), Charset.defaultCharset());
			FileUtils.createFile(sub.replace(template), file.getValue());
		}
    }
	
	private Map<String, String> getSourcesAndTarget(File directory, String scenarioName) {
		System.out.println("Scenario: " + scenarioName + ", Directory: " + directory.getAbsolutePath());
		Map<String, String> result = new HashMap<>();
		
		for(File file : directory.listFiles()) {
			
			if (file.isDirectory()) {
				result.putAll(getSourcesAndTarget(file, scenarioName));
			} else {
				String path = file.getAbsolutePath().substring(file.getAbsolutePath().indexOf(YAML_FOLDER));
				result.put(path, path.replace(YAML_FOLDER, "runner/testruns/"+scenarioName));
			}
		}
		return result;
	}
}
