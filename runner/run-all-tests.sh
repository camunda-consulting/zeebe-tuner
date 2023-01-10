#!/bin/bash
set -euo pipefail

TESTRUNS_DONE_DIR="testruns-done"

usage()
{
  echo ""
  echo "Usage: $0 <options>"
  echo "  -o <path> where to save a copy of testruns and csv file. default is '$TESTRUNS_DONE_DIR'"
  echo "  -h print this help message"
  echo ""
}

run()
{
  for filename in testruns/*/;
  do
    testScenarioName=$(basename "$filename")
	echo "Scenario $testScenarioName"
	  ./run-single-test.sh "$testScenarioName" "$TESTRUNS_DONE_DIR"
  done
}

while getopts "ho:" opt
do
  case "$opt" in
     (h) usage; exit 0;;
     (o) TESTRUNS_DONE_DIR=${OPTARG};;
     (*) usage; exit 0;;
  esac
done

run;
exit 0

