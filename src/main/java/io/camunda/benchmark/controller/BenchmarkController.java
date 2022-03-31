package io.camunda.benchmark.controller;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Map;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.camunda.benchmark.service.EksService;
import io.camunda.benchmark.service.ScenarioBuilderService;
import io.camunda.benchmark.service.TemplatingService;
import io.camunda.benchmark.zeebe.ZeebeStarterService;

@RestController
@RequestMapping("/benchmark")
@CrossOrigin(origins = "*")
public class BenchmarkController {

	@Autowired
	private ScenarioBuilderService scenarioBuilderService;

	@Autowired
	private TemplatingService templatingService;
	
	@Autowired
	private EksService eksService;

	@Autowired
	private ZeebeStarterService zeebeStarterService;
	
	@GetMapping(value = "/tearDown")
	public void tearDown() throws IOException, InterruptedException {
		eksService.cleanEksCluster();
	}
	
	@PostConstruct
    private void run() throws IOException, GeneralSecurityException, InterruptedException {
		scenarioBuilderService.BuildScenariiInputs();
		for(int i=0;i<scenarioBuilderService.getNbScenarii();i++) {
			Map<String, String> inputs = scenarioBuilderService.getInputs(i);
			
			templatingService.buildConfFiles(inputs);
		}
		
		/*if (inputs.get("target").equals("eks")) {
			eksService.createEksCluster();
			String urlGrafana = eksService.getUrlGrafana();
			zeebeStarterService.buildZeebe();
			zeebeStarterService.watchZeebe();
			zeebeStarterService.exposeZeebe();
			zeebeStarterService.deployProcess();
			zeebeStarterService.camundaCloudBenchmark();
			//TODO: checks Grafana/prometheurs peaks and then report them in GoogleSheet
			//TODO: when results drop down, tear down and move to next scenario
		}*/
    }
	
}
