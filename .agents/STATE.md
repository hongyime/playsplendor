# Current work

2026-09-11: Splendor maintenance under the accepted portfolio plan.

- Base: origin/main at ebb1f4fbe2e83bf17f44dfb8e7b52bfaa8ef6031; original checkout is clean. Work is isolated in a checkout whose path contains spaces.
- Task list before implementation: reproduce the Windows test-runner path failure; check the documented/shared gem display order; repair confirmed runner and assertion defects; test Windows/Linux behavior without starting live multiplayer; repair and verify the public Pages entry if its docs redirect is broken; publish, synchronize the original checkout and update both portfolio plans.
- Source inspection: Gem.displayOrder explicitly defines R G B W K Au, and the formatter uses it. One existing formatter test expects a different order. The batch runner concatenates unquoted absolute source paths. The Bash runner constructs a shell command with eval and its network-source exclusion pattern needs verification.
- Preserve all existing source, public card/config data, game logs and history. Do not run setup/download scripts or live multiplayer servers during this pass. No Supabase migration or paid service is introduced.
- Windows baseline confirms javac splits the checkout path at its first space. Quoting file arguments allows compilation and reaches the known formatter assertion. The full baseline now reaches 157 tests: 147 pass, nine documentation checks fail on removed/stale artifacts, and one formatter expectation disagrees with the shared UI definition. The expectation is corrected without changing production display order.
- Public target metadata: GitHub Pages uses main/root. The root HTML redirects to docs/javadoc/index.html, which is confirmed HTTP 404. Historical project documentation exists before cleanup commit 764ebfd; restoration/build review is in progress.
- A six-case Bash boundary harness uses synthetic Java tools only. Local Git Bash cannot fork (0xC0000142/resource-unavailable), so its timeouts are environment failures rather than runner evidence. Validate on hosted Linux before editing Bash behavior. Original source/data files remain preserved.
