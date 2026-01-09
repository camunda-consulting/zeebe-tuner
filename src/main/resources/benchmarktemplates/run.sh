echo "Waiting $((${loadGeneratorStarter.runDuration}/60)) minutes for completion of benchmark run ${testCaseName} ..."

if [[ "$(uname)" != "Darwin" ]] || command -v gtimeout >/dev/null 2>&1; then
    make logs-benchmark-timed
else
    echo "gtimeout is not installed. Using sleep instead. To install gtimeout run: brew install coreutils"
    sleep ${loadGeneratorStarter.runDuration}
fi