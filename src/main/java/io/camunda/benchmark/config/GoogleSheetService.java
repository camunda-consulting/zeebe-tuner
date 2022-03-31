package io.camunda.benchmark.config;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

@Service
public class GoogleSheetService {

	@Autowired
	private HttpTransport httpTransport;

	@Autowired
	private JsonFactory jsonFactory;
	
	@Autowired
	private KubeConfig kubeConfig;

	@Autowired
	private GoogleSheetConfig googleSheetConfig;
	
	
	private List<Map<String, String>> inputMaps = new ArrayList<>();
	
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
	
	public void read() throws IOException, GeneralSecurityException {
		ValueRange response = getSheets().spreadsheets().values()
                .get(googleSheetConfig.googleSheetId, googleSheetConfig.sheetInputs).execute();

		List<List<Object>> values = response.getValues();
        if (values == null || values.isEmpty()) {
            System.out.println("No data found.");
        } else {
        	Map<Integer, String> headersMap = new HashMap<>();
        	int idxRow=0;
            for (List<Object> row : values) {
            	int idxCol=0;
            	if (idxRow>0) {
            		inputMaps.add(new HashMap<>());
            		inputMaps.get(idxRow-1).put("kubePrefix", kubeConfig.kubePrefix);
            	}
            	for (Object cell : row) {
            		if (idxRow==0) {
            			headersMap.put(idxCol, (String) cell);
            		} else {
            			inputMaps.get(idxRow-1).put(headersMap.get(idxCol), (String) cell);
            		}
            		idxCol++;
	                // Print columns A and E, which correspond to indices 0 and 4.
	                //System.out.printf("%s, ", cell);
            	}
                //System.out.println("");
                idxRow++;
            }
        }
	}
	
	public Map<String, String> getInputs(int idx) {
		return inputMaps.get(idx);
	}
}
