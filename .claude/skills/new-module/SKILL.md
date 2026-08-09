---
name: new-module
description: Author a new Nextflow DSL2 module in this library. Use whenever the user asks to add, write, or create a module for a bioinformatics tool (fastp, star, samtools, macs2, bwa, minimap2, dorado, ...), or to wrap a tool so it can later be pulled into a pipeline.
---

# Add a module to this library

## 0. Check nf-core/modules first — the usual answer is "don't write it"

Look for the tool at `https://github.com/nf-core/modules/tree/master/modules/nf-core/<tool>`
(subtools nest: `samtools/index`, `star/align`).

- **Exists and fits** → do NOT author a copy here. Tell the user to install it straight from
  nf-core in their pipeline: `nf-core modules install <tool>`. Done.
- **Exists but needs real changes** (different interface, trimmed-down behavior) → author it
  here, but lift the upstream `container` lines, `environment.yml` pins, and stub shape
  verbatim. Never invent container tags or digests.
- **Doesn't exist** → author it here from scratch, modeled on an existing module in this repo.

## 1. Scaffold

Create `modules/jpfry327/<tool>/` (or `<tool>/<subtool>/`) with **four files**, using
`modules/jpfry327/fastqc/` as the pattern:

```
main.nf            process, UPPERCASE name matching the path (STAR_ALIGN for star/align)
environment.yml    conda-forge + bioconda channels, pinned tool version
meta.yml           inputs/outputs documented, nf-core meta format
tests/main.nf.test nf-test with at least one stub test (tag "stub", options "-stub")
```

House rules (each module, no exceptions):
- Channels are `[ meta, files ]`; key off `meta`, never hardcode meta field names.
- `conda "${moduleDir}/environment.yml"` + the two-URI `container` ternary (singularity/docker).
- No hardcoded tool flags — options come from `task.ext.args`; output basenames use
  `task.ext.prefix ?: "${meta.id}"`.
- Emit `versions.yml`; include a `stub:` block that touches every declared output and writes
  a literal versions.yml (stubs must not invoke the tool).
- Resource label: `process_single|low|medium|high` (+ `process_gpu` where relevant).
- Test inputs come from `params.modules_testdata_base_path` (nf-core test-datasets).

## 2. Test

Preferred (works in a cloud/phone session if Nextflow is installable, and on any laptop):

```bash
nf-test test modules/jpfry327/<tool> --tag stub
```

If Nextflow/nf-test can't run in the current environment: push the branch and watch the
`nf-test` GitHub Actions workflow instead — it runs all stub tests without containers and
the tagged `full` tests under docker. Iterate until green; that IS the verification.

## 3. Ship

Commit on a branch, push, merge to `main` once CI is green. The module is then pullable
from any pipeline with:

```bash
nf-core modules install --git-remote https://github.com/jpfry327/nf-modules.git --branch main <tool>
```

## Report back

State: library-check result (nf-core hit or authored here), files created, how it was
verified (local nf-test / CI run link / static only), and the install command for the HPC.
