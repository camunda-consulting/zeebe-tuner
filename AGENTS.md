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

## Running a generated test run

After `./gradlew bootRun` populates `runner/testruns/<id>/`, the top-level `runner/Makefile` resolves the lexicographically-first directory there and creates `runner/current/run` as a symlink to it. Operate the active run from there:

```sh
cd runner/current/run
make all          # full pipeline: kube-node-pool, helm install Camunda, deploy models, start benchmark
make clean        # clean-benchmark + uninstall-camunda
make clean all    # full reset
```

Useful finer-grained targets when iterating:
- `make deploy-models-zbctl-local` — port-forward to the gateway and `zbctl deploy resource` every model file. Faster than the k8s-job variant (`make deploy-models`) and gives direct stderr.
- `make benchmark` / `make clean-benchmark` — start/stop just the benchmark deployment.
- `make await-zeebe`, `make pods`, `make cpu-info.txt` — wait/inspect helpers.

The `models` variable defaults to `*.*mn` (matches both `.bpmn` and `.dmn`). To deploy a single file: `make deploy-models-zbctl-local models=FirePremium.bpmn`.

Finished runs are moved into `$(TESTRUNS_DONE_DIR)/<id>/` (configured in `config.mk`), and `runner/current/run` becomes a broken symlink — the top-level `runner/Makefile` auto-rebuilds the symlink to the next pending testrun the next time it's invoked.

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
- **Leak any customer-identifying information into this repo.** It is a public open-source project. That means no customer or project names in commit messages, code comments, sample data, screenshots, log excerpts, or filenames; no customer-owned BPMN/DMN models committed (even as test fixtures); no Sheet IDs, internal hostnames, or workload-specific configuration that would identify the customer. Use generic placeholders ("customer X", "project Y") in any documentation or test artefact that has to reference such material.
