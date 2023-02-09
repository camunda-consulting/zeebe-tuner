#echo "###############################################"
#echo "Running test for config: ${testCaseName}"

echo "Waiting ${loadGeneratorStarter.runDuration} seconds for completion of benchmark run ${testCaseName} ..."
sleep ${loadGeneratorStarter.runDuration}

# Start Zeebe
#echo 'Starting Zeebe...'
#make
