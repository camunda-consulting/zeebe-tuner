## Version 0.0.1-SNAPSHOT, June 28

- Added parameters for “fixed”, “gradient”, and “vegas” back pressure algorithms
- Added parameters for benchmark tool: `startPiIncreaseFactor` and `startRateAdjustmentStrategy`. Set `startRateAdjustmentStrategy=none` for long tests.
- Able to configure Disable Explicit Raft Flush Column from spreadsheet. 
- Grafana urls are printed to CSV
- Able to control payload used by repl***REMOVED***ng `payload.json` in the benchmarktemplates directory
- Fixed so `sleep` command works on BSD operating systems (including mac osx)
- First version of the project