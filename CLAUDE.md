# nf-modules — conventions

Personal library of Nextflow DSL2 modules. Pipelines built from
[nf-pipeline-template](https://github.com/jpfry327/nf-pipeline-template) install modules
with `scripts/module.sh add <tool>`, which copies `modules/jpfry327/<tool>/` into the
pipeline's `modules/lib/<tool>/` (skipping `tests/`) and records the commit in the pipeline's
`modules.json`. No nf-core CLI, no nf-schema.

## Adding a module
Use the **`new-module`** skill (`.claude/skills/new-module/`). Short version: nf-core/modules
is a reference for interface and stub shape only — always author the module here. Scaffold
`modules/jpfry327/<tool>/{main.nf,tests/main.nf.test}` from an existing module and verify
with the stub test.

## Hard conventions
- Channels are `[ meta, files ]`; never hardcode meta field names.
- One plain-string `container '...'` directive per module (serves docker and singularity).
  The URL comes from Josh; otherwise write the literal placeholder `<CONTAINER_URL>` and
  report it. Never look up or invent an image tag.
- No hardcoded tool flags (`task.ext.args`); basenames via `task.ext.prefix ?: "${meta.id}"`.
- Every module: `versions.yml` output + a `stub:` block covering every declared output.
- Every module: `tests/main.nf.test` with at least a stub test (`tag "stub"`, `options "-stub"`).

## Verification
`nf-test test --tag stub` locally when possible; otherwise push and let the `nf-test`
GitHub Actions workflow verify (stub tests run container-free).
