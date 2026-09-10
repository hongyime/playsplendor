# Current work

2026-09-11: Splendor production follow-up under the accepted portfolio plan.

- PR #148 merged at c2a483af61c672d1fd6ccad4b0bde4f294ae5cdb. The guide and current API are deployed to the existing GitHub Pages URL. Production run 34527372674 passed 149 non-network tests on Linux and Windows Java 17, six Bash fixtures and the isolated site build. All 113 published files match its artifact; source/card/config and ten archived diagram/source bytes are preserved.
- Production browser validation caught a missing optional DejaVu stylesheet in the Java 17 output. The follow-up uses existing system-font fallbacks when that optional file is absent and validates CSS URLs as well as HTML links. Four regression checks cover missing required images, optional/available fonts and embedded data URLs. Full production browser verification remains pending this follow-up.
- The old all-comment javadoc.yml is invalid to GitHub Actions. It now has a valid manual-only entry pointing maintainers to documentation.yml; historical comments remain inactive. The normal workflow is the only automatic Pages publisher.
- Automatic dependency update e7066dd0d47d1b67edc0f211f604b60a8cef0e70 is preserved. Legacy npm tooling still has open advisories; those packages are outside the normal JDK/Python site build.
- Next: verify the follow-up in hosted CI, publish, compare the final artifact and public browser behavior, synchronize the original checkout, and update the Markdown/PostPlan evidence. Then continue the portfolio rotation. Multiplayer runtime/resource bounds remain unverified; no server, real user records or paid service was started.
