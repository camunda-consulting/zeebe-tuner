#!/bin/bash
set -euo pipefail

# usage: ./run-single-test-teardown.sh <testrunDir> <testrunsDoneDir>
# example: ./run-single-test-teardown.sh testruns/769 ~/git/zeebe-benchmarks/optimize/testruns-done/

TESTRUN_DIR=${1:-'testruns/example'}
TESTRUNS_DONE_DIR=${2:-'testruns-done'}

dashboardId="zeebe-dashboard"
dashboardName="zeebe"

# get testScenarioName and startTime
source "${TESTRUN_DIR}/start-time.sh"

# get the endtime of the benchmark
endTime=$(date +%s000)
endTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "end time: ${endTimeIso}"

# cleanup
echo 'Finished. Cleaning up now...'
(cd "${TESTRUN_DIR}" && make clean)

# Generate Dashboard Links
echo 'Getting Graphana URL'
grafanaUrl=$(cd "${TESTRUN_DIR}" && make url-grafana --no-print-directory)
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

# add the configuration that was used to generate the test scenario
cp -r ../src/main/resources "${TESTRUN_DIR}/zeebe-tuner-config"

# create a symlink for quickly comparing the last test run (not (yet) used for execution)
mkdir -p last
rm -f last/run

if [ ! -d "${TESTRUNS_DONE_DIR}/${testScenarioName}" ]
then
  mv "${TESTRUN_DIR}" "${TESTRUNS_DONE_DIR}/"
  echo "Archived to $(realpath ${TESTRUNS_DONE_DIR}/${testScenarioName})"
  ln -s "${TESTRUNS_DONE_DIR}/${testScenarioName}" "last/run"
else
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  mv "${TESTRUN_DIR}" "${TESTRUNS_DONE_DIR}/${testScenarioName}_${timestamp}"
  echo "Archived to $(realpath ${TESTRUNS_DONE_DIR}/${testScenarioName}_${timestamp})"
  ln -s "${TESTRUNS_DONE_DIR}/${testScenarioName}_${timestamp}" "last/run"
fi
echo "Symlinked to $(realpath last/run)"

# immediately commit test config for colleagues to see
cd $TESTRUNS_DONE_DIR
git add . && git commit . -m "Add benchmark run ${testScenarioName}" && git push
cd -

echo "Benchmark ${testScenarioName} has been completed."