# nf-modules — conventions

Personal Nextflow DSL2 module library in nf-core custom-remote format
(`.nf-core.yml` → `org_path: jpfry327`). Pipelines pull modules with
`nf-core modules install --git-remote <this-repo> --branch main <tool>`.

## Adding a module
Use the **`new-module`** skill (`.claude/skills/new-module/`). Short version: check
nf-core/modules upstream first (if it exists there, don't duplicate it here); otherwise
scaffold `modules/jpfry327/<tool>/{main.nf,environment.yml,meta.yml,tests/}` from an
existing module and verify with the stub test.

## Hard conventions
- Channels are `[ meta, files ]`; never hardcode meta field names.
- `conda`/`container` directives live IN the module (nf-core style) — real, pinned
  image URIs only, never invented tags.
- No hardcoded tool flags (`task.ext.args`); basenames via `task.ext.prefix ?: "${meta.id}"`.
- Every module: `versions.yml` output + a `stub:` block covering every declared output.
- Every module: `tests/main.nf.test` with at least a stub test (`tag "stub"`, `options "-stub"`).

## Verification
`nf-test test --tag stub` locally when possible; otherwise push and let the `nf-test`
GitHub Actions workflow verify (stub tests run container-free).
