package io.camunda.benchmark;

import java.io.IOException;
import java.security.GeneralSecurityException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;

@SpringBootApplication
public class BenchmarkAutomateApplication {
	
	public static void main(String[] args) {
		SpringApplication.run(BenchmarkAutomateApplication.class, args);
		
		
	}
	
	@Bean(name = "httpTransport")
	public HttpTransport HttpTransport() throws GeneralSecurityException, IOException {

		return GoogleNetHttpTransport.newTrustedTransport();
	}

	@Bean(name = "jsonFactory")
	public JsonFactory JsonFactory() {
		
		return GsonFactory.getDefaultInstance();
	}

}
