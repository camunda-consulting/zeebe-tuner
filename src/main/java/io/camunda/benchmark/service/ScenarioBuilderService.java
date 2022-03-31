package io.camunda.benchmark.service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.google.api.services.sheets.v4.model.ValueRange;

import io.camunda.benchmark.config.KubeConfig;
import io.camunda.benchmark.utils.GgSheetHeaderUtils;

@Service
public class ScenarioBuilderService {
	
	@Autowired
	private KubeConfig kubeConfig;

	@Autowired
	private GoogleSheetService googleSheetService;
	
	private List<Map<String, String>> inputMaps = new ArrayList<>();
	
	public void BuildScenariiInputs() throws IOException, GeneralSecurityException {
		ValueRange response = googleSheetService.getValues();

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
            		inputMaps.get(idxRow-1).put("namespace", kubeConfig.namespace);
            		inputMaps.get(idxRow-1).put("region", kubeConfig.kubeRegion);
            	}
            	for (Object cell : row) {
            		if (idxRow==0) {
            			headersMap.put(idxCol, GgSheetHeaderUtils.toCamelCase((String) cell));
            		} else {
            			inputMaps.get(idxRow-1).put(headersMap.get(idxCol), (String) cell);
            		}
            		idxCol++;
            	}
                idxRow++;
            }
        }
	}
	
	public Map<String, String> getInputs(int idx) {
		return inputMaps.get(idx);
	}
	
	public int getNbScenarii() {
		return inputMaps.size();
	}
}
