# AGENTS.md

## Read these first

- **[README.md](README.md)** — what Nokogiri is and its guiding principles.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to set up, build, test, format, and submit changes.
  This is the canonical guide; read it before making any change.
- **[`adr/`](adr/)** — architectural decision records. Check here before changing cross-cutting
  native behavior (memory management, symbol visibility, etc.).

## Expectations

- **CRuby and JRuby must have feature parity.** Nokogiri ships separate native
  implementations for CRuby and JRuby. Any feature or bugfix that changes behavior must be
  implemented for *both*, with tests for both.
- Every behavior change requires a test demonstrating it.
- Features and bugfixes need a `CHANGELOG.md` entry in the "unreleased" section.
- `main` is the merge base for all pull requests.
