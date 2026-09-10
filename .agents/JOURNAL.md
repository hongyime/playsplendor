# Decisions

- 2026-09-11: Reproduce runner failures in a separate checkout containing spaces, preserving the original checkout and game data. Confirm the intended shared display order before changing a failing assertion.
- 2026-09-11: Hosted baselines reproduced four Bash runner defects and Windows Java 17 encoding errors; the focused fixes now pass. Replace missing generated-document/tool-presence assertions with native Javadoc coverage, preserve five archived diagram pairs byte-for-byte, and publish only an isolated static artifact after both OS test suites pass.
- 2026-09-11: Public Java 17 API browser checks found a font import absent from the generated artifact. Check CSS references during builds and use the existing fallback only for that missing optional stylesheet. Preserve a concurrent Dependabot update and repair the invalid, fully commented legacy workflow without restoring its historical deployment commands.
