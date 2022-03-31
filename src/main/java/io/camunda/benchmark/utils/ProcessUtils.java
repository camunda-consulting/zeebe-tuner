package io.camunda.benchmark.utils;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.io.IOUtils;

public class ProcessUtils {

	private ProcessUtils() {
		
	}
	
	public static Map<String, Object> execBlocking(String cmd) throws IOException, InterruptedException {
		Map<String, Object> result = new HashMap<>();
		Process process = Runtime.getRuntime().exec(cmd);
		InputStream is = process.getInputStream();
		while (process.isAlive()) {
			Thread.sleep(200);
		}
		result.put("exitCode", process.exitValue());
		result.put("output", IOUtils.toString(is));
		return result;
	}
	
}
