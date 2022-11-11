#!/bin/bash

testScenarioName=${1:-'example'}
TESTRUNS_DONE_DIR=${2:-'testruns-done'}
TESTRUNS_DIR="testruns"
dashboardId="uX16GP3nk"

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

# get the start time of the run
# Note that grafana expects timestamps as millis since epoch
startTime=$(date +%s000)
startTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "start time = $startTimeIso"

# Start Zeebe
echo 'Starting Zeebe...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make)

# wait for the starter job to be finished
echo 'Waiting for completion of benchmark run...'
#kubectl wait --for=condition=complete job/starter --timeout=1200s
sleep 1200

# cleanup
echo 'Finished. Cleaning up now...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make clean)

# get the endtime of the run
endTime=$(date +%s000)
endTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "end time = $endTimeIso"

# Generate Dashboard Links

echo 'Getting Graphana URL'
grafanaUrl=$(cd "${TESTRUNS_DIR}/${testScenarioName}" && make url-grafana)
#grafanaUrl="http://34.73.2.98/d/I4lo7_EZk/zeebe?var-namespace=camunda"
echo $grafanaUrl

#http://34.73.2.98/d/uX16GP3nk/zeebe-low-latency?orgId=1&from=1656406606147&to=1656407414704&var-DS_PROMETHEUS=Prometheus&var-namespace=camunda&var-pod=All&var-partition=All

#get and parse dashboard id
#parse the IP Address from the base grafana url
ipAddress="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$grafanaUrl")"

# create the url to the low-latency dashboard in the correct time frame
grafanaUrl="http://$ipAddress/d/$dashboardId/zeebe-low-latency?orgId=1&from=$startTime&to=$endTime&var-DS_PROMETHEUS=Prometheus&var-namespace=camunda&var-pod=All&var-partition=All"
#echo $grafanaUrl

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


