package io.camunda.benchmark.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class GoogleSheetConfig {

	@Value("${google.sheetid}")
	public String googleSheetId;
	
	@Value("${google.inputs}")
	public String sheetInputs;
	
	@Value("${google.oauth.clientid}")
	public String googleClientId;

	@Value("${google.oauth.clientsecret}")
	public String googleClientSecret;

	@Value("${google.oauth.callbackPort}")
	public Integer oauthCallbackPort;

	@Value("${google.oauth.username}")
	public String googleUsername;
}
