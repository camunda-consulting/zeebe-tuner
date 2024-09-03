#echo "###############################################"
#echo "Running test for config: ${testCaseName}"

helm search repo camunda/camunda-platform --output yaml > helm-chart-version.yaml

echo "Waiting $((${loadGeneratorStarter.runDuration}/60)) minutes for completion of benchmark run ${testCaseName} ..."
sleep ${loadGeneratorStarter.runDuration}

# Start Zeebe
#echo 'Starting Zeebe...'
#make
