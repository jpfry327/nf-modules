# nf-modules

Personal library of Nextflow DSL2 modules. Modules are authored and tested here, then
copied into pipelines built from
[nf-pipeline-template](https://github.com/jpfry327/nf-pipeline-template) by the template's
own installer, `scripts/module.sh`, which records the source commit in the pipeline's
`modules.json`. No nf-core CLI, no nf-schema.

## Layout

```
modules/jpfry327/<tool>[/<subtool>]/
    main.nf                                   process (meta map, ext.args, container, stub)
    tests/main.nf.test                        nf-test (stub test minimum); not installed
subworkflows/jpfry327/<name>/main.nf          reusable module chains
tests/config/nf-test.config                   test params + docker/singularity profiles
.github/workflows/nf-test.yml                 CI: stub tests (no containers) + docker tests
```

Each module is exactly what a pipeline receives: the installer copies `main.nf` (plus any
helper files next to it) and skips `tests/`.

## Authoring a module (from anywhere, including your phone)

Point a Claude Code session at this repo and ask for the tool you need — the
`new-module` skill drives the process:

1. Use nf-core/modules upstream as a reference for the interface and stub shape only.
   Modules are always authored here; nothing is installed from nf-core.
2. Scaffold `modules/jpfry327/<tool>/` (two files, modeled on `fastqc/`).
3. Container: one plain-string `container '...'` directive. Josh supplies the URL; until
   then the module carries the literal placeholder `<CONTAINER_URL>`. Never guess a tag.
4. Verify: `nf-test test modules/jpfry327/<tool> --tag stub` locally, or push a branch
   and let the `nf-test` GitHub Actions workflow run it.
5. Merge to `main` when green.

## Using a module in a pipeline

From inside a pipeline made from the template:

```bash
scripts/module.sh add fastp              # -> modules/lib/fastp/main.nf, recorded in modules.json
scripts/module.sh add samtools/index     # nested tools keep their path
scripts/module.sh add star/align --ref <branch|tag|sha>
scripts/module.sh list | update --all | remove <tool>
```

The installer prints the `include { ... }` line to paste into `workflows/pipeline.nf`.
Tool flags, output names, and container overrides go in the pipeline's `conf/modules.config`
(`withName: 'TOOL' { ext.args = '...'; container = '...' }`).

### Subworkflows

`scripts/module.sh` does not yet support subworkflows. To use one, copy
`subworkflows/jpfry327/<name>/main.nf` into the pipeline by hand, install the modules it
includes with `scripts/module.sh add`, and fix the `include` paths to point at
`modules/lib/`.

## Local testing

```bash
nf-test test --tag stub                    # every stub test, no containers needed
nf-test test --tag full --profile docker   # real-tool tests
```
