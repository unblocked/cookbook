# Judging the risk

The assessment's rationale comes from heuristics that match on paths and change shapes. It often flags safe things and misses the one that isn't. Verify every claim against the code before repeating it, and say where you disagree.

## What genuinely raises risk

Reachability from production traffic. A change under a service directory matters only if something on a live path calls it. Trace the callers locally and ask Unblocked what calls the changed code and what incidents or decisions involve it. Admin-only, batch-only, and dead code are a different risk class from the request path.

Schema changes that aren't purely additive: dropping or retyping a column, adding a non-null column without a default, anything that rewrites a large table or holds a long lock. A nullable column is additive and rollback-safe; say so rather than inheriting a "destructive migration" claim.

New failure modes on write paths, such as I/O added inside an existing transaction, where a failure now aborts work that used to succeed.

New behavior the tests don't exercise. A touched test file is not coverage; check that an assertion fails if the new branch breaks.

Irreversibility. If reverting the deploy doesn't undo it, that is the headline risk regardless of diff size.

Silent failure. A mistake that yields wrong output is worse than one that crashes. Look for lookups that return a default on a miss.

Behavior changes outside a feature flag, where the repo's conventions expect one.

## Feeding it back into the policy

Labels come from `.unblocked/risk-policies.yaml`. Each matching policy sets a minimum score and the highest match sets the floor, so you can always tell which policy produced a label. When your reading and a policy floor diverge, the policy is usually too coarse. Name the policy, quote its current `criteria`, and give replacement wording that separates this change from the one the policy targets. Propose it in the notes for a human to land as a small PR.

## Applying changes

Keep edits minimal, mechanical, and self-contained, in the surrounding style. Leave untouched lines and the PR's intent as they are. A small diff plus a clear note beats a large speculative diff.

## Verification belongs to the author

Report the likely test command instead of guessing or running one, unless the user gave you the exact command.

| Present in repo | Likely command |
|---|---|
| `package.json` | `npm test` or the `scripts.test` entry |
| `Cargo.toml` | `cargo test` |
| `go.mod` | `go test ./...` |
| `pyproject.toml`, `tox.ini` | `pytest` |
| `build.gradle`, `build.gradle.kts` | `./gradlew test` scoped to the changed module |
| `pom.xml` | `mvn test` |
| `Makefile` with a `test:` target | `make test` |
