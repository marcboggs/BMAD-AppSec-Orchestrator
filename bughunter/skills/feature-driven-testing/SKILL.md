---
name: feature-driven-testing
description: Feature-driven testing router — the complement to the vuln-class hunt-* skills. When you are staring at an application FEATURE (a signup form, a login/reset flow, an account/profile editor, a developer/OAuth/API-key console, the core business feature, a payment/upgrade flow, a file upload) and need to know what to probe, this maps each feature to the exact questions to ask and the hunt-* skills to dispatch into. Built on zseano's "test the features in front of you + hunt filters first" methodology. Use when onboarding a new program/app surface, when you've found a feature but aren't sure what it's vulnerable to, when asking "what do I test on this form/flow?", or to drive a systematic first-pass over an app before deep vuln-class hunting. Pairs with bb-methodology (session orchestration) and routes into hunt-xss, hunt-idor, hunt-oauth, hunt-open-redirect, hunt-ssrf, hunt-file-upload, hunt-csrf, hunt-business-logic, hunt-forgot-password, hunt-cors and others.
---

# Feature-Driven Testing

Your `hunt-*` skills are organized by **vulnerability class** ("how do I find XSS?").
This skill is the other axis — **by application feature** ("I'm looking at a signup
form, what do I probe, and which hunt-* skill do I hand off to?").

Use it as a **router**, not a payload library. Each feature below lists the questions
to ask and the `hunt-*` skills to dispatch into. The depth lives in those skills; this
skill decides *where to point them*.

---

## PART 0: The three operating principles

Apply these across every feature. They decide *order* and *what counts as a lead*.

1. **Filter-first, not bug-first.** On the initial pass, hunt for **filters**, not
   bugs. A filter (XSS blocklist, redirect allowlist, upload extension check, CSRF
   token, SSRF internal-IP block) marks a parameter the *developer already knew was
   dangerous*. That is a lead to chase, and it reveals their overall security posture.
   Prove a feature *has* protection, then work out how it was built and whether it can
   be bypassed. **Where there's a filter, there's usually a bypass.**

2. **Reverse-engineer the developer, then look for reuse.** When you find a filter,
   ask *why* it exists and *where else the same code runs*. Filters, parameter names,
   and token formats get copy-pasted across the app. **One bug = many**: a bypass on a
   "harmless" endpoint is often reusable on a sensitive one later.

3. **Every feature has a second codebase.** The same feature on **mobile app, a
   different TLD (.cn/.es), the developer subdomain, or a "coming soon" beta** is often
   a *different, weaker* implementation. XSS filtered on desktop is frequently open on
   mobile. Re-test every feature across every surface. Note it, don't assume parity.

> As you go: write notes (interesting endpoints, params, filters, token formats), and
> turn found endpoints/params into **custom wordlists** (per-domain + global). This
> flywheel feeds `web2-recon` and `hunt-shadow-api`.

---

## PART 1: Feature → probe → dispatch

### 1. Registration / signup
**Questions**
- What inputs does signup accept (display name, bio, avatar, URL field), and **where
  is each reflected** — only after completing signup? on desktop *and* mobile? when
  interacting (posting, adding a friend), not just on the profile?
- What characters survive in each field: `< > " '`, unicode, `%00 %0d %0a %09 %07`?
- Can you register with a **`@target.com` email**? If it's blocklisted — *why*? Special
  privileges? Try to bypass (`user%00@target.com`, subaddressing, unicode).
- OAuth/social signup present? → token-leak surface.
- Revisit the register page **while authenticated** — does it redirect, and is the
  redirect parameter-controlled?

**Dispatch** → `hunt-xss` (reflected + **blind**, every field), `hunt-file-upload`
(avatar), `hunt-oauth` (social signup), `hunt-open-redirect` (post-signup redirect),
`hunt-business-logic` (`@target.com` privilege), `hunt-idor` (user-id in signup API).

### 2. Login / password reset
**Questions**
- Is there a **redirect parameter** on login (`returnUrl`, `goto`, `return_url`,
  `returnTo`, `back`, `cancelUrl` — try upper/lower variants even if not visible)?
- Does `user%00@email.com` get read as `user@email.com`? (login + signup null-byte →
  account-collision ATO).
- **Password reset:** what parameters? Try injecting an `id` param (HPP/IDOR). Is the
  **Host header trusted** in the reset link (`Host: evil.com` → token leak)? Token
  entropy/expiry/single-use?
- OAuth/social login — same codebase as signup, or a separate connect flow?
- Mobile login flow differences?

**Dispatch** → `hunt-open-redirect` (+ chain into OAuth token theft via `hunt-oauth`),
`hunt-forgot-password` / `hunt-host-header` (reset poisoning), `hunt-ato`
(null-byte collision, reset → takeover), `hunt-mfa-bypass` (if 2FA present),
`hunt-brute-force` (**check policy first — often out of scope/informative**).

### 3. Account / profile update
**Questions**
- **CSRF protection** on sensitive updates? (Expect it — this is a filter to probe.)
  Blank token? Same-length token? Framework error leak on malformed token?
- **Step-up / re-auth** on email or password change? If none → chain with XSS for ATO.
- How are `< > " '` / unicode / `%09 %0d%0a` handled, and where reflected (bio,
  display name reflected into a JS context like `onclick="runjs('…')"` → break out with
  `');`)?
- Profile **URL field** → `javascript:` filtering?
- **Avatar/media upload** — same filter as elsewhere, or different? Stored on root
  domain or a CDN (is the CDN in the CSP)?
- Everything above re-tested on the **mobile API** (often IDOR + weaker filters)?

**Dispatch** → `hunt-csrf`, `hunt-xss` (DOM/stored, incl. JS-context breakout →
`hunt-dom`), `hunt-ato` (missing step-up + XSS), `hunt-file-upload`, `hunt-idor`
(mobile profile API), `hunt-open-redirect` (`javascript:` in URL field).

### 4. Developer tools (OAuth apps / API keys / webhooks / GraphQL explorer)
**Questions**
- Where are these hosted — self-hosted vs **AWS** (if AWS, aim at metadata/keys)?
- **Webhook / URL-taking features** present (webhook test, "fetch URL", import) →
  primary SSRF surface. Always test redirect handling + chain a found open redirect.
- **API key / OAuth scopes:** generate a key limited to scope X — does it actually
  enforce X? Press **"Cancel"/"Deny"** on consent — is a token issued anyway, and does
  it have permissions it shouldn't?
- `redirect_uri` / `returnTo` handling — whitelisted to `*.target.com/*`? Try
  `target.com` substring tricks, `localhost`, `amazonaws.com`.
- Do the **API docs** reveal extra endpoints, how tokens authenticate (needed to weaponize a leaked token into P1), and keywords for your wordlist?
- Separate dev-site account, or shared session with main domain via a redirect token
  exchange? (→ that open redirect again.)

**Dispatch** → `hunt-ssrf` (webhooks/URL features, → `cloud-iam-deep` if AWS creds
surface), `hunt-oauth` (scope/consent/`redirect_uri` flaws), `hunt-idor` /
`hunt-api-misconfig` (broken scope enforcement, mass assignment), `hunt-graphql`
(explorer), `hunt-source-leak` / `hunt-shadow-api` (API docs → endpoints/keywords).

### 5. The core business feature
> Whatever the business is built around (Dropbox→file sharing, a mail product→mail,
> a shop→checkout). This is where logic bugs and "one bug = many" live.
**Questions**
- Map it **top-down**; note whether everything funnels through one pattern (all
  GraphQL? a shared `xyz_id=` param? → one bug, many places).
- **Privacy/permission toggles:** is that "private" post actually private? Can a
  guest/free role invoke moderator/paid API calls?
- **Role matrix:** sign up as each role (admin/mod/user/guest) and cross-call.
- **Old / "coming soon" / deprecated features** — flip `true`/`false`, find old
  indexed files, commented-out code referencing unreleased functionality.
- Same features present/identical on **mobile and other TLDs**?

**Dispatch** → `hunt-business-logic` (privacy, role matrix, flow abuse),
`hunt-idor` (shared id params, cross-role), `hunt-graphql` / `hunt-api-misconfig`,
`hunt-race-condition` (state-changing actions), `hunt-source-leak` (old files / JS
with pre-release endpoints).

### 6. Payment / upgrade
**Questions**
- What unlocks on upgrade — can a free account reach paid features **without paying**?
- Are **sandbox/test card numbers** accepted in production (bypass verification /
  claim ownership)? (Known test PANs exist for WorldPay/PayPal/Stripe.)
- Do payment options differ **by country** (switch locale to reach a weaker flow)?
- Is payment data in the DOM → chain XSS to exfiltrate for higher impact?

**Dispatch** → `hunt-business-logic` (free→paid, verification bypass via sandbox
details, locale-switch), `hunt-xss` (DOM payment-data exfil chain), `hunt-idor`
(order/invoice objects), `hunt-race-condition` (coupon/balance double-spend).

> ⚠️ Testing payments uses the target's **real** payment flows. Use only the payment
> provider's **published test values** and stay within program scope. Never enter real
> financial instruments; never execute real transfers. If a flow would move real funds,
> stop and report the finding instead of completing it.

### 7. File upload (cross-cutting — appears inside features 1/3/4)
**Questions**
- Assume a filter exists; map it. Try `.txt`, `.svg`, `.xml` first (often forgotten).
- Upload one image → how is it stored (re-encoded to `.jpg`? original kept?)
- Filename tricks: `shell.php/.jpg`, `file.html%0d%0a.jpg`, double ext, trailing dot,
  no extension; filename **reflected** on the page → XSS via `filename="x<svg …>"`.
- Content-Type vs extension vs magic-byte trust (`‰PNG` header + `<script>` body).
- Stored on root domain (RCE/stored-XSS potential) or isolated CDN?

**Dispatch** → `hunt-file-upload` (primary), `hunt-xss` (SVG/HTML/filename reflection),
`hunt-rce` (if executable lands on an interpreting host), `hunt-xxe` (SVG/DOCX/XML).

---

## PART 2: First-pass routine (how to drive this skill)

For a newly chosen program, before deep vuln-class hunting:

1. **Pre-recon leads.** Check Google / HackerOne Hacktivity / OpenBugBounty for prior
   disclosures on the target — old bugs give instant leads and sometimes still bypass.
2. **Walk the feature list top-down** (features 1→6 above), assuming the app *is*
   secure. For each: run the questions, note filters found, dispatch into the matching
   `hunt-*` skill only when a lead appears.
3. **Record** interesting endpoints/params/filters/token-formats → notes + wordlists.
4. **Expand surface** (hand to `web2-recon` / `hunt-subdomain` / `hunt-shadow-api`),
   then **re-walk the main app again** — second pass on JS files, per-endpoint `.js`,
   pre-release feature flags. (Set up `.js` change monitoring; see `web2-recon`.)
5. **Rinse & repeat** across 5–6 wide-scope programs; depth compounds over months.

## Cross-references
- **Session orchestration / when-to-do-what:** `bb-methodology`
- **Surface expansion & monitoring:** `web2-recon`, `hunt-subdomain`, `hunt-shadow-api`,
  `hunt-source-leak`
- **Program choice & triage:** `recon-scope-triage`, `bounty-program-selection`
- **Reporting:** `report-writing`, `triage-validation`, `evidence-hygiene`
