# Zeebe Tuner

A set of tools that can run series of benchmarks on a Kubernetes cluster based on configuration parameters from a spreadsheet. If you don't have a Kubernetes cluster yet, have a look at [Camunda 8 Kubernetes Installation](https://github.com/camunda-community-hub/camunda8-greenfield-installation).

## Initial setup

0. Clone the following GitHub projects into the same parrent folder:
    * https://github.com/camunda-consulting/zeebe-tuner (this project)
    * https://github.com/camunda-community-hub/camunda-8-helm-profiles (dependencies)
1. Create a copy of the [Zeebe Benchmark Result Template](https://docs.google.com/spreadsheets/d/1YZFp5uDd4783qTr7fvQIyXzoz8o01GLadurXLXU9sMc).
   This is were you will plan your test runs.
   (see also: [Camunda Blog: Zeebe Performance Tuning tool](https://camunda.com/blog/2020/11/zeebe-performance-tool/))
2. Enter the id of your spreadsheet in [application.yml](src/main/resources/application.yml) as `google.sheetId` and ensure that `google.inputs` matches your sheet's parameter range.
3. Enter your Google username in [application.yml](src/main/resources/application.yml) as `google.oauth.username`. This will be the user whom's data are accessed, e.g. the spreadsheet above.
4. [Create a Google Cloud project](https://developers.google.com/workspace/guides/create-project).
5. Create OAuth client credentials for a desktop application, refer to [Create credentials](https://developers.google.com/workspace/guides/create-credentials).
6. Enter the app credentials in [application.yml](src/main/resources/application.yml) as `google.oauth.clientid` and `google.oauth.clientsecret`.
7. Start the Spring Boot application for the first time using your IDE or `./gradlew bootRun` and it will print an authentication link in the console that you have to open in your browser.
8. After that you will get an error message in the console containing another link to enable the Google Sheets API for your project. Click on the and you're all set.

## Running a series of brenchmarks against a Kubernetes cluster
0. Enter the configuration parameters for the benchmarks you want to schedule in your copy of the [Zeebe Benchmark Result Template](https://docs.google.com/spreadsheets/d/1YZFp5uDd4783qTr7fvQIyXzoz8o01GLadurXLXU9sMc).
1. Start the Spring Boot application.
   For each row in the spreadsheet it will create a folder and generate
   Helm chart values, Kubernetes manifests and a Makefile to run the benchmark
   in `runner/testruns`.
2. Stop the Spring Boot application.
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
