# STRIDE Quick Reference

| Category | Property violated | Typical questions to ask per component/flow |
|---|---|---|
| **S**poofing | Authentication | Can an entity claim to be something/someone it isn't? Are identities of users, services, or devices verified before trust is extended? |
| **T**ampering | Integrity | Can data (in transit, at rest, or in memory) be modified by an unauthorized party? Are there integrity checks (signatures, hashes, parameterized queries)? |
| **R**epudiation | Non-repudiation | Can an actor deny performing an action? Is there sufficient logging/audit trail tied to authenticated identity? |
| **I**nformation Disclosure | Confidentiality | Can data be exposed to someone not authorized to see it? Consider logs, error messages, caches, backups, third-party calls. |
| **D**enial of Service | Availability | Can a component be made unavailable or degraded? Consider unbounded resource use, missing rate limits, expensive operations reachable pre-auth. |
| **E**levation of Privilege | Authorization | Can an actor gain capabilities beyond what they were granted? Consider missing authz checks, insecure direct object references, privilege boundaries crossed by trusted input. |

## Severity heuristic (likelihood × impact)

- **Critical** — remotely exploitable pre-auth, or trivially exploitable with high impact (RCE, auth bypass, mass data exposure)
- **High** — exploitable with some precondition (authenticated user, specific config), significant impact
- **Medium** — requires chained conditions or privileged access; moderate impact
- **Low** — theoretical, requires unlikely preconditions, or low impact even if exploited

## Corroboration note

A STRIDE threat backed by a secreview SAST/SCA finding (matching CWE/CVE, same
component) should generally be bumped at least one severity level above a purely
design-level threat with no scan evidence — it's no longer hypothetical.
