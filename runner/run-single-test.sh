#!/bin/bash
set -euo pipefail

testScenarioName=${1:-'example'}
TESTRUNS_DONE_DIR=${2:-'testruns-done'}
TESTRUNS_DIR="testruns"

echo "###############################################"
echo "Running test scenario: ${testScenarioName}"

# Function to generate start-time.sh with benchmark timing information
generate_start_time_script() {
    local scenario_name="$1"
    local testruns_dir="$2"
    
    # get the start time of the benchmark
    # Note that grafana expects timestamps as millis since epoch
    local startTime=$(date +%s000)
    local startTimeIso=$(date +"%Y-%m-%d %H:%M:%S")
    echo "start time: ${startTimeIso}"

    cat <<EOF > "${testruns_dir}/${scenario_name}/start-time.sh"
#!/bin/bash
set -euo pipefail
testScenarioName="${scenario_name}"
startTime="${startTime}"
startTimeIso="${startTimeIso}"
echo "test scenario: \${testScenarioName}"
echo "start time: \${startTimeIso}"
EOF
}

# Generate a preliminary start-time.sh script
generate_start_time_script "${testScenarioName}" "${TESTRUNS_DIR}"

# Start Zeebe
echo 'Starting Zeebe...'
(cd "${TESTRUNS_DIR}/${testScenarioName}" && make)

# Re-generate the start-time.sh script with the actual start time
generate_start_time_script "${testScenarioName}" "${TESTRUNS_DIR}"

# test that generated start-time.sh is working
source "${TESTRUNS_DIR}/${testScenarioName}/start-time.sh"

# execute dynamic sleep in generated run.sh file
(cd "${TESTRUNS_DIR}/${testScenarioName}" && source run.sh)
# TODO run c8b as a job (see: https://github.com/falko/zeebe-benchmark/blob/hackdays-2020/Dockerfile#L28) and wait the job to be finished, e.g. using:
#kubectl wait --for=condition=complete job/starter --timeout=1200s

./run-single-test-teardown.sh "$TESTRUNS_DIR/$testScenarioName" "$TESTRUNS_DONE_DIR"


