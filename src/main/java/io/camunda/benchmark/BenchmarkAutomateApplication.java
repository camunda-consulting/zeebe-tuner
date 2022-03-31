package io.camunda.benchmark;

import java.io.IOException;
import java.security.GeneralSecurityException;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;

import io.camunda.benchmark.config.GoogleSheetService;

@SpringBootApplication
public class BenchmarkAutomateApplication {

	@Autowired
	static GoogleSheetService google;
	
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
