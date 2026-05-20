# Zeebe Tuner — Agent Instructions

## What this repo does
Spring Boot (Java 21, Gradle) tool that reads benchmark configurations from a Google Sheets spreadsheet and generates per-test-run folders under `runner/testruns/<id>/`, each containing a `Makefile`, Helm values, and Kubernetes manifests ready to execute.

## Repo layout
```
src/main/java/io/camunda/benchmark/   # Spring Boot app (services, controller, templating)
src/main/resources/benchmarktemplates/ # Makefile + YAML templates stamped into each test run
src/main/resources/application.yml    # Google OAuth + Sheet config (not committed with real secrets)
runner/                               # Shell scripts that iterate through generated test runs
runner/testruns/<id>/                 # Generated; one folder per spreadsheet row
runner/testruns-done/                 # Finished runs (configured via TESTRUNS_DONE_DIR in config.mk)
models/                               # Shared BPMN/DMN models and payloads
config.mk                             # Local overrides: TESTRUNS_DONE_DIR, modelDir
```

## Key dependencies (sibling repos — must be cloned at the same level)
- `camunda-8-helm-profiles` — included as `$(root)/…` from generated Makefiles

## Build & run
```sh
./gradlew bootRun          # generate test runs from spreadsheet → runner/testruns/
make install               # run-all-tests.sh, moves done runs to TESTRUNS_DONE_DIR
make teardown-current-run  # tear down the currently active test run
```

## Cloud provider detection (in generated Makefiles)
Machine type name pattern → provider:
- contains `.` → AWS (e.g. `c8g.4xlarge`)
- starts with `Standard_` → Azure
- otherwise → GKE (e.g. `c4-standard-8`)

## Config conventions
- `config.mk` sets `TESTRUNS_DONE_DIR` and `modelDir` (not tracked with real paths)
- `application.yml`: set `google.sheetId`, `google.oauth.username`, `google.oauth.clientid/clientsecret`
- Delete `credStore/StoredCredential` to force re-auth

## Coding conventions
- Templates in `src/main/resources/benchmarktemplates/` use `${variableName}` placeholders stamped by `TemplatingService`
- Makefile targets must use hard tabs (not spaces)
- Use `?=` for all Make variables to allow caller override
- Idempotent infra targets: check existence before create (e.g. `kube-node-pool` uses `gcloud … describe` before `create`)
- `zbctl` deploy loops must fail-fast on first error (`|| exit 255` inside `xargs sh -c`)

## Do not
- Commit real OAuth credentials or `credStore/StoredCredential`
- Edit files under `runner/testruns/` or `runner/testruns-done/` — they are generated/output artifacts
- Add features beyond what a spreadsheet row drives without updating the template + `ScenarioBuilderService`
