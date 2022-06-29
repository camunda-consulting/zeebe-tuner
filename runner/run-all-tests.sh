#!/bin/bash
mkdir testruns-done
for filename in testruns/*/;
do
#    testScenarioName=$(basename "$filename")
    echo "$filename";
#	  mv $filename "testruns/$testScenarioName.yaml"
	  ./run-single-test.sh "$filename"
#    mv "testruns/$testScenarioName.yaml" testruns/done/
    mv "$filename" testruns-done/
done
