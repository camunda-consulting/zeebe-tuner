#!/bin/bash
set -euo pipefail

testScenarioName=${1:-'example'}
TESTRUNS_DONE_DIR=${2:-'testruns-done'}
TESTRUNS_DIR="testruns"
dashboardId="zeebe-dashboard"
dashboardName="zeebe"

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

# Start Zeebe
echo 'Starting Zeebe...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make)

# get the start time of the benchmark
# Note that grafana expects timestamps as millis since epoch
startTime=$(date +%s000)
startTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "start time = $startTimeIso"

# execute dynamic sleep in generated run.sh file
(cd "${TESTRUNS_DIR}/${testScenarioName}" && source run.sh)
# TODO run c8b as a job (see: https://github.com/falko/zeebe-benchmark/blob/hackdays-2020/Dockerfile#L28) and wait the job to be finished, e.g. using:
#kubectl wait --for=condition=complete job/starter --timeout=1200s

# get the endtime of the benchmark
endTime=$(date +%s000)
endTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "end time = $endTimeIso"

# cleanup
echo 'Finished. Cleaning up now...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make clean)

# Generate Dashboard Links
echo 'Getting Graphana URL'
grafanaUrl=$(cd "${TESTRUNS_DIR}/${testScenarioName}" && make url-grafana --no-print-directory)
#GCP: http://34.79.232.100/d/zeebe-dashboard/zeebe?var-namespace=camunda
#AWS: http://a6a265857589c4623922c83765970a12-346210104.us-east-2.elb.amazonaws.com/d/zeebe-dashboard/zeebe?var-namespace=camunda
echo $grafanaUrl
grafanaUrl=$(echo "$grafanaUrl&from=$startTime&to=$endTime" | sed "s|zeebe-dashboard/zeebe|$dashboardId/$dashboardName|")
echo $grafanaUrl

if [ ! -d "$TESTRUNS_DONE_DIR" ]; then
  mkdir $TESTRUNS_DONE_DIR
fi

#create a csv with the params (link to dashboard) (toTime) (fromTime) (id of dashboard)
csvFile="$TESTRUNS_DONE_DIR/grafanalinks.csv"
if [ -e $csvFile ]
then
   echo "writing line $csvFile"
   echo "\"=HYPERLINK(\"\"$grafanaUrl\"\", \"\"$testScenarioName\"\")\"", "\"$startTimeIso\"", "\"$endTimeIso\"" >> $csvFile
else
   echo "creating file $csvFile"
   touch $csvFile
   echo "Scenario", "Start Time", "End Time" >> $csvFile
   echo "\"=HYPERLINK(\"\"$grafanaUrl\"\", \"\"$testScenarioName\"\")\"", "\"$startTimeIso\"", "\"$endTimeIso\"" >> $csvFile
fi

if [ ! -d "${TESTRUNS_DONE_DIR}/${testScenarioName}" ]
then
  mv "${TESTRUNS_DIR}/${testScenarioName}" "${TESTRUNS_DONE_DIR}/"
else
  rm -rf "${TESTRUNS_DIR}/${testScenarioName}"
fi

# immediately persist test config
#cp -r ../src/main/resources "${TESTRUNS_DONE_DIR}/zeebe-tuner-config"
#cd $TESTRUNS_DONE_DIR
#git add . && git commit . -m "Add benchmark run ${testScenarioName}" && git push
#cd -

echo "Benchmark ${testScenarioName} has been completed."