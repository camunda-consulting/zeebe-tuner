#!/bin/bash

testScenarioName=${1:-'example'}

echo "###############################################"
echo "Running test for config: ${testScenarioName}"

cd ${testScenarioName}

# Start Zeebe
echo 'Starting Zeebe...'
make

## wait for the starter job to be finished
echo 'Waiting for completion of benchmark run...'
#kubectl wait --for=condition=complete job/starter --timeout=1200s
sleep 1200

#############
## Cleanup
echo 'Finished. Cleaning up now...'
make clean