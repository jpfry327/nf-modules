---
name: new-module
description: Author a new Nextflow DSL2 module in this library. Use whenever the user asks to add, write, or create a module for a bioinformatics tool (fastp, star, samtools, macs2, bwa, minimap2, dorado, ...), or to wrap a tool so it can later be pulled into a pipeline.
---

# Add a module to this library

## 0. nf-core/modules is a reference, not a source

Look at `https://github.com/nf-core/modules/tree/master/modules/nf-core/<tool>` (subtools
nest: `samtools/index`, `star/align`) for the **interface and stub shape only**: input/output
tuples, emit names, which files the stub touches, the `versions.yml` command. Josh does NOT
pull anything from nf-core into pipelines, so author the module here regardless of whether
upstream has one. Lift only the process body; leave behind upstream package-manager
directives, YAML sidecar files, and container ternaries.

## 1. Scaffold

Create `modules/jpfry327/<tool>/` (or `<tool>/<subtool>/`) with **two files**, using
`modules/jpfry327/fastqc/` as the pattern:

```
main.nf            process, UPPERCASE name matching the path (STAR_ALIGN for star/align)
tests/main.nf.test nf-test with at least one stub test (tag "stub", options "-stub")
```

House rules (each module, no exceptions):
- Channels are `[ meta, files ]`; key off `meta`, never hardcode meta field names.
- **One plain-string `container '...'` directive**, preceded by the two-line comment used in
  every existing module (single image for docker+singularity; override per pipeline in
  `conf/modules.config` with `withName: 'TOOL' { container = '...' }`). Josh supplies the
  URL (Seqera Containers or a `.sif` path). If he has not given one, write the literal
  placeholder `container '<CONTAINER_URL>'` and report it as an open item. Never look up
  or invent an image tag.
- No hardcoded tool flags — options come from `task.ext.args`; output basenames use
  `task.ext.prefix ?: "${meta.id}"`.
- `when: task.ext.when == null || task.ext.when`.
- Emit `versions.yml`; include a `stub:` block that touches every declared output and writes
  a literal versions.yml (stubs must not invoke the tool).
- Resource label: `process_single|low|medium|high` (+ `process_gpu` where relevant).
- Test inputs come from `params.modules_testdata_base_path` (nf-core test-datasets).

The pipeline installer copies `main.nf` and any helper files beside it, and skips `tests/`.

## 2. Test

Preferred (works in a cloud/phone session if Nextflow is installable, and on any laptop):

```bash
nf-test test modules/jpfry327/<tool> --tag stub
```

If Nextflow/nf-test can't run in the current environment: push the branch and watch the
`nf-test` GitHub Actions workflow instead — it runs all stub tests without containers and
the tagged `full` tests under docker. Iterate until green; that IS the verification.

## 3. Ship

Commit on a branch, push, merge to `main` once CI is green. The module is then installable
from inside any pipeline made from nf-pipeline-template with:

```bash
scripts/module.sh add <tool>             # e.g. fastp, or samtools/index
```

## Report back

State: files created, the container URL used (or `<CONTAINER_URL>` still to be filled in),
how it was verified (local nf-test / CI run link / static only), and the install command.
