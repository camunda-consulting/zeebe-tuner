package io.camunda.benchmark.utils;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import com.google.common.io.Files;

public class FileUtils {

	private FileUtils() {
		
	}
	
	public static void createFile(String content, String targetPath) throws IOException {
		Path path = Paths.get(targetPath);
	    java.nio.file.Files.createDirectories(path.getParent());
	    Files.write(content.getBytes(), path.toFile());
	}
}
