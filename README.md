# Zeebe Tuner

A set of tools that can run series of benchmarks on a Kubernetes cluster based on configuration parameters from a spreadsheet. If you don't have a Kubernetes cluster yet, have a look at [Camunda 8 Kubernetes Installation](https://github.com/camunda-community-hub/camunda8-greenfield-installation).

## Initial setup

0. Clone the following GitHub projects into the same parrent folder:
    * https://github.com/camunda-consulting/zeebe-tuner (this project)
    * https://github.com/camunda-community-hub/camunda-8-helm-profiles (dependencies)
1. Create a copy of the [Zeebe Benchmark Result Template](https://docs.google.com/spreadsheets/d/19jSD20aXuJiXBIvZVhWpcMiMQNokshv40s8kvOdea4c).
   This is were you will plan your test runs.
   (see also: [Camunda Blog: Zeebe Performance Tuning tool](https://camunda.com/blog/2020/11/zeebe-performance-tool/))
2. Enter the id of your spreadsheet in [application.yml](src/main/resources/application.yml) as `google.sheetId` and ensure that `google.inputs` matches your sheet's parameter range.
3. Enter your Google username in [application.yml](src/main/resources/application.yml) as `google.oauth.username`. This will be the user whom's data are accessed, e.g. the spreadsheet above.
4. [Create a Google Cloud project](https://developers.google.com/workspace/guides/create-project).
5. Create OAuth client credentials for a desktop application, refer to [Create credentials](https://developers.google.com/workspace/guides/create-credentials).
6. Enter the app credentials in [application.yml](src/main/resources/application.yml) as `google.oauth.clientid` and `google.oauth.clientsecret`.
7. Start the Spring Boot application for the first time using your IDE or `./gradlew bootRun` and it will print an authentication link in the console that you have to open in your browser.
8. After that you will get an error message in the console containing another link to enable the Google Sheets API for your project.
```
Please open the following address in your browser:                        
  https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=000000000000-your-client-id-will-appear-here.apps.googleusercontent.com&redirect_uri=http://localhost:8888/Callback&response_type=code&scope=https://www.googleapis.com/auth/spreadsheets
```
9. Click on the link and allow Zeebe Tuner to read your spreadsheet.

## Running a series of brenchmarks against a Kubernetes cluster
0. Enter the configuration parameters for the benchmarks you want to schedule in your copy of the [Zeebe Benchmark Result Template](https://docs.google.com/spreadsheets/d/19jSD20aXuJiXBIvZVhWpcMiMQNokshv40s8kvOdea4c).
1. Start the Spring Boot application using your IDE or `./gradlew bootRun`.
   For each row in the spreadsheet it will create a folder and generate
   Helm chart values, Kubernetes manifests and a Makefile to run the benchmark
   in `runner/testruns`.
2. The Spring Boot application will automatically stop once all test runs have been generated.
3. Go to `runner/testruns` and delete older test runs that you already executed in earlier runs.
   Currently, the tool will export all rows regardless of whether they have results or not (see #3).
4. Ensure `kubectl` is setup to connect to your Kubernetes cluster that should have Prometheus and Grafana set up already.
4. Open a terminal in `runner` and run `./run-all-tests.sh` to kick off the iteration through your scheduled benchmarks.
   (see `./run-all-tests.sh -h` for available parameters,
   e.g. where to move finished testruns and create CSV file.
   Default is `runner/testruns-done`)
5. Import the generated CSV file into Google Sheets and
   copy the first two collums with Grafana link and Timestamp into your result spreadsheet.
6. Use Grafana to measure performance and enter the readings into the spreadsheet.

## Troubleshooting
### TokenResponseException: 400 Bad Request
If you get the following error when starting the application:
```
com.google.api.client.auth.oauth2.TokenResponseException: 400 Bad Request
POST https://oauth2.googleapis.com/token
{
  "error": "invalid_grant",
  "error_description": "Bad Request"
}
```
delete the file `credStore/StoredCredential`
and follow steps 7 to 9 of the initial setup described above.

### No processes starting
1. Check log output of `job.batch/zbctl-deploy` for deployment failures using:
   ```sh
   cd runner/current/run
   make logs-job-deploy-models
   ```
   There could be messages indicating BPMN parsing issues or duplicate process ids
2. Check log output of `benchmark` pod for startup failures using:
   ```sh
   cd runner/current/run
   make logs-benchmark
   ```
3. Check Grafana > gRPC > `Total gRPC reqests` for any `CreateProcessInstance (NOT_FOUND)`.
   ```sh
   cd runner/current/run
   make open-grafana
   ```
   This could indicate that the process id configured in the spreadsheet does not match the one in the deployed BPMN file.
### Process instances not completing
1. Check Grafana > Throughput > `Job Completion Per Second` and compare it with the rate of `Process instance completion per second` multiplied with the number of jobs your are expecting to execute. If too few jobs are executed you may have:
   * Payload variables that 
      * Make Gateways routing the wrong way
      * Cause incidents (can be detected by checking the
        [metrics](https://docs.camunda.io/docs/self-managed/zeebe-deployment/operations/metrics/#available-metrics) 
        `zeebe_incident_events_total` and 
        `zeebe_pending_incidents_total`,
        which are not (yet) exposed by the Zeebe Grafana Dashboard)
