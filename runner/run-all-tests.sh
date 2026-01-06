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
  while true; do
    find testruns -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r testScenarioDir; do
      testScenarioName=$(basename "$testScenarioDir")
      echo "Scenario $testScenarioName"
      # create a symlink for quickly debugging the current test run using Makefile
      make current/run NEXT_TESTRUN="$testScenarioDir"
      ./run-single-test.sh "$testScenarioName" "$TESTRUNS_DONE_DIR"
      make clean # remove debug symlink
    done
    sleep 10 # just so that it doesn't busyloop
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

