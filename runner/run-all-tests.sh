#!/bin/bash
mkdir testruns/done
for filename in $(ls -1 testruns/new/*.yaml | sort -t '-' -k 2 -n -r); do
    testScenarioName=$(basename "$filename" .yaml)
	mv $filename "testruns/$testScenarioName.yaml"
    ./run-single-test.sh "$testScenarioName"
    mv "testruns/$testScenarioName.yaml" testruns/done/
    mv "testruns/$testScenarioName" testruns/done/
done
