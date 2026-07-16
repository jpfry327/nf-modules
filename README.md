# nf-modules

Personal library of hand-written Nextflow DSL2 modules. Single source of truth;
pipelines **vendor** (copy) what they need rather than depending on this repo at runtime.

## Layout
```
modules/<tool>/main.nf     the process (meta map, ext.args, versions block)
modules/<tool>/meta.yml    documentation (nf-core-lint compatible)
subworkflows/<name>/main.nf reusable module chains
```

## House conventions
- Every channel is `[ meta, files ]`; modules key off `meta` (never hardcode meta field names).
- Tool options come from the pipeline's `conf/modules.config` via `task.ext.args` — not the module.
- Output basenames use `task.ext.prefix ?: meta.id`.
- Every module emits `versions.yml`.
- Modules carry NO container/conda directive. The image is declared per-process in the
  consuming pipeline's `conf/containers.config` (singularity `oras://` URI or local `.sif`).
- Resource label is one of `process_low|process_medium|process_high`.

## Using a module in a pipeline (vendoring)
Copy the module folder into your pipeline's `modules/local/`, then record where it came from:
```bash
cp -r nf-modules/modules/fastp  my-pipeline/modules/local/fastp
# then log the source commit in my-pipeline/modules/local/modules.json (see that file)
```
Re-vendor deliberately when you want a library fix; pipelines don't auto-update.

## nf-core tooling (optional)
`nf-core modules install` can vendor from this repo AND record the git SHA for you
(`--git-remote <this-repo-url>`). If you go that route you'll also want `environment.yml`
and `tests/` per module, and the `conda "${moduleDir}/environment.yml"` container idiom.
The meta.yml files here are written for that format; run `nf-core modules lint --fix`
to reconcile with your installed tools version.
