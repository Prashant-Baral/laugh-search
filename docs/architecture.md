# LaughSearch — Architecture

## What LaughSearch actually is

LaughSearch doesn't crawl the web or build its own index — it's a
**metasearch engine**: it forwards a query to several existing search
engines in parallel and merges the results into one page. The engine doing
that work is [SearXNG](https://github.com/searxng/searxng), an open-source
project. LaughSearch is SearXNG, configured and branded — not rewritten.

## Request flow

```
Browser
   │  GET /search?q=...
   ▼
LaughSearch  (SearXNG, configured)
   │  fans the query out in parallel
   ▼
Google · Bing · Wikipedia
   │  each responds independently
   ▼
LaughSearch  (merges, dedupes, ranks)
   ▼
Browser  (renders one results page)
```

## Components

| Component | Role |
|---|---|
| **SearXNG** | The metasearch application — receives queries, calls out to engines, renders results. |
| **Valkey** | Backs SearXNG's rate limiter and bot-detection cache. |
| **Docker** | Packages SearXNG + LaughSearch's config and branding into one reproducible image, baked in via the `Dockerfile` — no bind mounts needed in production. |
| **Render** | Hosts the packaged image as a public web service. |

## Branding — how the favicon actually works

This turned out to be the fiddliest part of the whole project, worth
documenting precisely:

- SearXNG serves favicon files from
  `/usr/local/searxng/searx/static/themes/simple/img/`.
- A raw PNG can't just be renamed to `.svg` — the server tells the browser
  "this is `image/svg+xml`" based on the extension, and the browser then
  fails to parse binary PNG data as XML. The fix: wrap the PNG as a
  base64 data URI inside real SVG markup, so `favicon.svg` is syntactically
  valid.
- SearXNG also pre-compresses static assets. `favicon.svg.gz` and
  `favicon.svg.br` exist alongside `favicon.svg`, and browsers request
  compressed responses by default — so those two compressed siblings must
  be overridden too, or the server keeps serving the *original* compressed
  file regardless of what's mounted at the plain `.svg` path.
- `favicon.png` and `favicon.ico` have no such compressed siblings, so
  those override cleanly with a direct file copy.

## Why Docker at all?

SearXNG has real Python dependency requirements that differ from a
laptop's environment, plus a companion cache service (Valkey). Docker
packages "SearXNG + config + branding + runtime" as one unit that behaves
identically locally and on Render.

## Privacy model — precisely

**What LaughSearch does:**
- No user accounts, no login.
- Doesn't persist search history anywhere.
- No analytics, no donation/contact/privacy-policy chrome from upstream
  SearXNG defaults.
- SafeSearch set to moderate by default.

**What LaughSearch can't control:**
- Every query is still forwarded to Google, Bing, and Wikipedia. Those
  services see the query and the IP it came from, and are subject to their
  own logging and privacy policies.
- This is **not** "100% anonymous" search. It removes the tracking layer
  LaughSearch itself would otherwise add; it doesn't erase what upstream
  engines do on their end.

## Known limitations

- Google actively rate-limits/CAPTCHAs rapid or automated-looking queries
  from a single IP — observed directly during local testing (`CAPTCHA
  (suspended_time=3600)` in the logs after a burst of test searches).
  SearXNG suspends that engine for an hour and keeps serving results from
  the others; this is expected behavior for a self-hosted metasearch
  instance, not a bug.
- Render's free tier cold-starts after inactivity.
- Only three engines are enabled (Google, Bing, Wikipedia) — trimmed
  deliberately to keep the surface area small for a one-day project.
