package io.camunda.benchmark.service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.util.store.FileDataStoreFactory;
import com.google.api.services.sheets.v4.Sheets;
import com.google.api.services.sheets.v4.SheetsScopes;
import com.google.api.services.sheets.v4.model.ValueRange;

import io.camunda.benchmark.config.GoogleSheetConfig;

@Service
public class GoogleSheetService {

	@Autowired
	private HttpTransport httpTransport;

	@Autowired
	private JsonFactory jsonFactory;

	@Autowired
	private GoogleSheetConfig googleSheetConfig;
	
	public Credential authorize() throws IOException {

		List<String> scopes = Arrays.asList(SheetsScopes.SPREADSHEETS);
		FileDataStoreFactory dataStoreFactory = new FileDataStoreFactory(new java.io.File("credStore"));
		GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(httpTransport, 
				jsonFactory, 
				googleSheetConfig.googleClientId, 
				googleSheetConfig.googleClientSecret, 
				scopes).setDataStoreFactory(dataStoreFactory)
				.setAccessType("offline").build();
		 
		final LocalServerReceiver receiver = new LocalServerReceiver.Builder().setPort(googleSheetConfig.oauthCallbackPort).build();
        Credential credential =
			    new AuthorizationCodeInstalledApp(flow, receiver).authorize(googleSheetConfig.googleUsername);
		return credential;
	}
	
	public Sheets getSheets() throws IOException, GeneralSecurityException {
        
        return new Sheets.Builder(
        		httpTransport, 
        		jsonFactory, this.authorize())
          .setApplicationName("Google sheet")
          .build();
    }
	
	
	public ValueRange getValues() throws IOException, GeneralSecurityException {
		return getSheets().spreadsheets().values()
                .get(googleSheetConfig.googleSheetId, googleSheetConfig.sheetInputs).execute();
	}
	
}
