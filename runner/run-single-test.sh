#!/bin/bash
set -euo pipefail

testScenarioName=${1:-'example'}
TESTRUNS_DONE_DIR=${2:-'testruns-done'}
TESTRUNS_DIR="testruns"

echo "###############################################"
echo "Running test scenario: ${testScenarioName}"

# Start Zeebe
echo 'Starting Zeebe...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make)

# get the start time of the benchmark
# Note that grafana expects timestamps as millis since epoch
startTime=$(date +%s000)
startTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
echo "start time: ${startTimeIso}"

cat <<EOF > "${TESTRUNS_DIR}/${testScenarioName}/start-time.sh"
#!/bin/bash
set -euo pipefail
testScenarioName="${testScenarioName}"
startTime="${startTime}"
startTimeIso="${startTimeIso}"
echo "test scenario: \${testScenarioName}"
echo "start time: \${startTimeIso}"
EOF

# test that generated start-time.sh is working
source "${TESTRUNS_DIR}/${testScenarioName}/start-time.sh"

# execute dynamic sleep in generated run.sh file
(cd "${TESTRUNS_DIR}/${testScenarioName}" && source run.sh)
# TODO run c8b as a job (see: https://github.com/falko/zeebe-benchmark/blob/hackdays-2020/Dockerfile#L28) and wait the job to be finished, e.g. using:
#kubectl wait --for=condition=complete job/starter --timeout=1200s

./run-single-test-teardown.sh "$TESTRUNS_DIR/$testScenarioName" "$TESTRUNS_DONE_DIR"