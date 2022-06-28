#!/bin/bash

testScenarioName=${1:-'example'}

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

cd ${testScenarioName}

# get the start time of the run
startTime=$(date +%s)
echo "start time = $(date -r $startTime)"

# Start Zeebe
echo 'Starting Zeebe...'
make

# wait for the starter job to be finished
echo 'Waiting for completion of benchmark run...'
#kubectl wait --for=condition=complete job/starter --timeout=1200s
sleep 1200


# cleanup
echo 'Finished. Cleaning up now...'
make clean

# get the endtime of the run
endTime=$(date +%s)
echo "end time = $(date -r $endTime)"

# Generate Dashboard Links

echo 'Getting Graphana URL'
grafanaUrl=$(make url-grafana)
#grafanaUrl="http://34.73.2.98/d/I4lo7_EZk/zeebe?var-namespace=camunda"
echo $grafanaUrl

#http://34.73.2.98/d/uX16GP3nk/zeebe-low-latency?orgId=1&from=1656406606147&to=1656407414704&var-DS_PROMETHEUS=Prometheus&var-namespace=camunda&var-pod=All&var-partition=All

#get and parse dashboard id
dashboardId="uX16GP3nk"

#parse the IP Addess from the base grafana url
ipAddress="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$grafanaUrl")"

# get the end time of the run after the clean
fromTime=$startTime
toTime=$endTime

# create the url to the low-latency dashboard in the correct time frame
grafanaUrl="http://$ipAddress/d/uX16GP3nk/zeebe-low-latency?orgId=1&from=$fromTime&to=$toTime&var-DS_PROMETHEUS=Prometheus&var-namespace=camunda&var-pod=All&var-partition=All"
echo $grafanaUrl

#create a csv with the params (link to dashboard) (toTime) (fromTime) (id of dashboard)
csvFile="../../testruns-done/grafanalinks.csv"
if [ -e $csvFile ]
then
   echo "writing line $csvFile"
   echo "$testScenarioName", "$(date -r $fromTime)", "$(date -r $toTime)", "$dashboardId", "$grafanaUrl" >> $csvFile
else
   echo "creating file $csvFile"
   touch $csvFile
   echo "Scenario Name", "From Time", "To Time", "Dashboard Id", "Grafana Url" >> $csvFile
   echo "$testScenarioName", "$(date -r $fromTime)", "$(date -r $toTime)", "$dashboardId", "$grafanaUrl" >> $csvFile
fi
