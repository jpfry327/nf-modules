# nf-modules

Personal library of Nextflow DSL2 modules in **nf-core custom-remote format**.
Modules are authored and tested here, then pulled into pipelines with the nf-core CLI —
which copies the files *and* records the source commit in the pipeline's `modules.json`.

## Layout

```
.nf-core.yml                                  repository_type: modules, org_path: jpfry327
modules/jpfry327/<tool>[/<subtool>]/
    main.nf                                   process (meta map, ext.args, container, stub)
    environment.yml                           pinned conda env (matches the container)
    meta.yml                                  interface docs
    tests/main.nf.test                        nf-test (stub test minimum)
subworkflows/jpfry327/<name>/                 reusable module chains
tests/config/nf-test.config                   test params + docker/singularity/conda profiles
.github/workflows/nf-test.yml                 CI: stub tests (no containers) + docker tests
```

## Authoring a module (from anywhere, including your phone)

Point a Claude Code session at this repo and ask for the tool you need — the
`new-module` skill drives the process:

1. Check nf-core/modules upstream. If the tool already exists there, stop: install it
   straight from nf-core in your pipeline instead of duplicating it here.
2. Otherwise scaffold `modules/jpfry327/<tool>/` (four files, modeled on `fastqc/`).
3. Verify: `nf-test test modules/jpfry327/<tool> --tag stub` locally, or push a branch
   and let the `nf-test` GitHub Actions workflow run it.
4. Merge to `main` when green.

## Using a module in a pipeline (at the HPC)

```bash
pip install nf-core
cd my-pipeline    # needs .nf-core.yml with repository_type: pipeline

# from this library:
nf-core modules install --git-remote https://github.com/jpfry327/nf-modules.git --branch main fastp

# tools that live in the official repo install directly:
nf-core modules install fastqc
```

`--branch main` is required (the CLI defaults to `master`). Updates later:
`nf-core modules update --git-remote ... --branch main <tool>`.

## Local testing

```bash
nf-test test --tag stub                    # every stub test, no containers needed
nf-test test --tag full --profile docker   # real-tool tests
```
