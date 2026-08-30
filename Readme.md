# LaughSearch

A privacy-focused metasearch engine built on [SearXNG](https://github.com/searxng/searxng), packaged with Docker, and deployed on Render.

**Repo:** https://github.com/Prashant-Baral/laugh-search

## What is LaughSearch?

LaughSearch doesn't crawl the web or build its own index — it forwards a
query to Google, Bing, and Wikipedia in parallel and merges the results
into one page, with no accounts, no stored search history, and no
analytics on my end. See [`docs/architecture.md`](docs/architecture.md)
for exactly what that does and doesn't protect you from.

## Why SearXNG?

Building a competing search index from scratch is a multi-year
undertaking. SearXNG already solves the hard part — talking to search
engines' APIs and scraped endpoints and normalizing their results — as an
active open-source project. LaughSearch is a **configuration and
deployment** of SearXNG, not a rewrite of it.

## Architecture

```
Browser → LaughSearch (SearXNG, configured) → Google · Bing · Wikipedia
```

Full breakdown — including exactly how the custom favicon works around
SearXNG's static-file precompression — in
[`docs/architecture.md`](docs/architecture.md).

## Privacy model

- No accounts. No stored search history. No analytics.
- SafeSearch set to moderate by default.
- **Not** "100% anonymous": queries are still forwarded to the upstream
  engines, which see the query and LaughSearch's server IP. See
  [`docs/architecture.md`](docs/architecture.md#privacy-model--precisely)
  for the precise version of this claim.

## Repository layout

```
laugh-search/
├── docker-compose.yml     # local dev: SearXNG + Valkey, config/branding mounted for fast iteration
├── Dockerfile             # production image: upstream SearXNG + config/branding baked in
├── .env                   # local secrets (NOT committed — see .gitignore)
├── searxng/
│   ├── settings.yml       # branding, privacy defaults, trimmed engine list
│   └── assets/            # favicon.png, favicon.ico, favicon-wrapped.svg(.gz/.br), logo.png
├── docs/
│   └── architecture.md
└── LICENSE
```

## Local installation

Requires Docker + Docker Compose.

```bash
git clone https://github.com/Prashant-Baral/laugh-search.git
cd laugh-search
# create .env with SEARXNG_SECRET and SEARXNG_BASE_URL — see docker-compose.yml
docker compose up -d
```

Open http://localhost:8080. Confirm:

- [ ] a plain search works
- [ ] `!go`, `!bi`, `!wp` each return results on their own
- [ ] the tab favicon and homepage branding show correctly

## Docker installation (production image)

The production image bakes `searxng/settings.yml` and every branding
asset into the official upstream image, so the same artifact runs
anywhere with no volume mounts:

```bash
docker build -t laughsearch .
docker run -p 8080:8080 \
  -e SEARXNG_BASE_URL=https://laugh-search.onrender.com/ \
  -e SEARXNG_SECRET=$(openssl rand -hex 32) \
  laughsearch
```

## Configuration

All of it lives in `searxng/settings.yml`:

- `use_default_settings.engines.keep_only` — trims SearXNG's default
  engines down to Google, Bing, Wikipedia.
- `general.enable_metrics: false`, `donation_url/contact_url/privacypolicy_url: false`
  — no analytics, no extra chrome.
- `search.safe_search: 1` — moderate SafeSearch.
- `ui.theme_args.simple_style: dark` + a `custom_css` override for the
  homepage logo, since it's a full-color image rather than the single-tone
  mask SearXNG's theme expects there.

Two settings to revisit before this instance is truly public:
- `server.limiter` is currently `false` — fine for local testing, but
  should be `true` once this is live on Render, backed by Valkey/Redis,
  or the instance risks getting rate-limited by upstream engines fast.
- `general.debug` is currently `true` — turn this off for production; it
  produces verbose logs and isn't meant for a public-facing instance.

## Branding

The favicon override needed more than just dropping a PNG in — see
[`docs/architecture.md`](docs/architecture.md#branding--how-the-favicon-actually-works)
for exactly why, and how the wrap-as-SVG + gzip/brotli-sibling fix works.
To swap the image later, regenerate `favicon-wrapped.svg`, `.svg.gz`, and
`.svg.br` from the new PNG using the same steps.

## Deploying on Render

1. Push this repo to GitHub.
2. In Render: **New → Web Service**, connect the repo, choose Docker as
   the environment.
3. Add a managed Redis/Key-Value instance if `server.limiter` is enabled,
   and point `SEARXNG_REDIS_URL` / `SEARXNG_VALKEY_URL` at its connection
   string.
4. Set `SEARXNG_BASE_URL` to the real public URL and `SEARXNG_SECRET` to a
   fresh random string.
5. Once live, connect a custom domain under **Settings → Custom Domain**.

## Limitations

- Google actively CAPTCHAs bursts of automated-looking queries from one
  IP — observed directly while testing. SearXNG suspends that engine for
  an hour and keeps serving results from the others; documented, not
  "fixed."
- Render's free tier cold-starts after inactivity.
- Only three engines enabled, deliberately, to keep this a one-day
  project rather than an open-ended SearXNG customization exercise.

## What I learned

*(Fill this in after finishing deployment and running through the test
checklist — that's the part actually worth writing.)*
