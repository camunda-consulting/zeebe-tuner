package io.camunda.benchmark.service;

import java.io.FileInputStream;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.google.api.services.sheets.v4.model.ValueRange;

import io.camunda.benchmark.config.KubeConfig;
import io.camunda.benchmark.utils.GgSheetHeaderUtils;

@Service
public class ScenarioBuilderService {

//	@Value("${ccb.bpmnfile}")
//	public String bpmnFile;

	@Autowired
	private KubeConfig kubeConfig;

	@Autowired
	private GoogleSheetService googleSheetService;
	
	private List<Map<String, String>> inputMaps = new ArrayList<>();
	
	
	public void BuildScenariiInputs() throws IOException, GeneralSecurityException {
		
//		FileInputStream bpmnFileIs = new FileInputStream(bpmnFile);
//	    String processFileContent = IOUtils.toString(bpmnFileIs, "UTF-8").replaceAll("(>[^<]*<)", "><");
        
		ValueRange response = googleSheetService.getValues();

		List<List<Object>> values = response.getValues();
        if (values == null || values.isEmpty()) {
            System.out.println("No data found.");
        } else {
        	Map<Integer, String> headersMap = new HashMap<>();
        	Map<Integer, String> prefixHeadersMap = new HashMap<>();
        	String prefixHeader="";
        	int idxRow=0;
            for (List<Object> row : values) {
            	int idxCol=0;
            	if (idxRow>1) {
            		inputMaps.add(new HashMap<>());
//            		inputMaps.get(idxRow-2).put("bpmnProcessFile", processFileContent);
            		inputMaps.get(idxRow-2).put("namespace", kubeConfig.namespace);
            		inputMaps.get(idxRow-2).put("region", kubeConfig.kubeRegion);
            	}
            	for (Object cell : row) {
            		String value = (String) cell;
            		if (idxRow==0) {
            			if (value.length()==0) {
            				prefixHeadersMap.put(idxCol, prefixHeader);
            			} else {
            				prefixHeader = GgSheetHeaderUtils.toCamelCase(value)+".";
                			prefixHeadersMap.put(idxCol, prefixHeader);
            			}
            		} else if (idxRow==1) {
            			headersMap.put(idxCol, GgSheetHeaderUtils.toCamelCase(value));
            		} else {
            			if (prefixHeadersMap.containsKey(idxCol)) {
            				prefixHeader = prefixHeadersMap.get(idxCol);
            			}
            			inputMaps.get(idxRow-2).put(prefixHeader+headersMap.get(idxCol), (String) cell);
            		}
            		idxCol++;
            	}
            	if (idxRow>1) {
            	  String vcpu = inputMaps.get(idxRow-2).get("engine.vcpus");
            	  try {
            	    int vcpuRequest = Integer.valueOf(vcpu)-1;
            	    inputMaps.get(idxRow-2).put("engine.vcpuRequest",String.valueOf(vcpuRequest));
            	  } catch (NumberFormatException nfe) {
            	    inputMaps.get(idxRow-2).put("engine.vcpuRequest",String.valueOf(vcpu));
                }
              	String nbNodesStr = inputMaps.get(idxRow-2).get("engine.clusterSize");
              	try {
                  int nbNodes = Integer.valueOf(nbNodesStr);
                  String evenBrokers="";
                  String oddBrokers="";
                  for(int i=0;i<nbNodes;i++) {
                    if (i%2==0) {
                      evenBrokers+="          - camunda-zeebe-"+i+"\n";
                    } else {
                      oddBrokers+="          - camunda-zeebe-"+i+"\n";
                    }
                  }
                  inputMaps.get(idxRow-2).put("evenBrokers",evenBrokers);
                  inputMaps.get(idxRow-2).put("oddBrokers",oddBrokers);
                } catch (NumberFormatException nfe) {
                }
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
