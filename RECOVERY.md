# golumin.io after the relaunch: what broke, and the fixes

**Status: proposal. Nothing here is implemented.**
Written 2026-10-28, after the design went live on Worker `golumin-site`.
Every claim below was checked against the live domain, the CMS and the
repository on the day.

## First, the reassuring part: nothing was deleted

`cms trash` is empty. Zero pages, zero entries, zero forms, zero globals,
zero assets. Every piece of content that was ever published is still in the
CMS exactly as it was.

What happened is not deletion. golumin.io used to be served by the CMS, and
now it is served by a static site that was built with a smaller set of
pages. The CMS still holds everything; the new site just does not render all
of it, and the Worker in front does not redirect the addresses that moved.
So this is a routing and coverage problem, and all of it is recoverable from
content that is still sitting there.

---

## 1. The form no longer records a conversion, anywhere

**This is the most expensive item on the page and it is invisible from the
front end: the form works, the lead arrives, and nothing is measured.**

### How it used to work

1. The visitor submitted the form.
2. The browser went to `/thank-you?form=<slug>&back=<path>`.
3. `/thank-you` showed the confirmation written for that specific form, then
   fired, once per lead and never twice for the same one:
   - `dataLayer.push({ event: "lead_submitted", lead_id, form_location })`
   - the Google Ads conversion, `AW-18424158289/mTzKCPb8uvUcENGwqdFE`,
     with the lead id as `transaction_id`
   - the OpenAI conversion
4. The lead id was kept in `localStorage` so a refresh could not double-count.

### What happens now

The form posts by `fetch` and reveals an inline "done" panel. The page never
navigates. `/thank-you` is still there and still returns 200, but nothing
sends anyone to it, it has no per-form variants any more, and it fires
nothing.

Worse, the tags are not on the site at all. The live pages contain no Google
Tag Manager container, no `gtag`, no `dataLayer`, no Google Analytics. The
CMS's Scripts global still holds `GTM-WX6GWCTQ` and `AW-18424158289`; the
static build never carried them over.

### What that costs, concretely

- **Google Ads has had no conversion signal since launch.** Smart Bidding on
  the GoLumin account is optimising against nothing.
- No analytics of any kind: no sessions, no sources, no landing page data.
- The per-form thank-you copy is gone.
- `cta_click`, `use_referral_calculator`, `page_not_found` and
  `view_human_gate` events are all gone too.

### The fix

1. Put GTM `GTM-WX6GWCTQ` back in the `<head>` of all 39 pages. Mechanical.
2. Decide the post-submit behaviour. Two options:
   - **(a) Restore the redirect.** On a 2xx, go to
     `/thank-you?form=<slug>&lead=<id>&back=<path>`, and port the old
     confirmation block onto `thank-you.html`. Identical to the old
     behaviour, so the Google Ads conversion and the GTM triggers keep
     working with no changes on the Ads side. **Recommended.**
   - **(b) Keep the inline panel and fire the conversion in place.** Nicer
     to use, no page load. But every GTM trigger and the Ads conversion have
     to be rebuilt around a custom event, and the per-form thank-you copy
     needs somewhere else to live.
3. Either way, verify with a real submission that the conversion shows up in
   Google Ads, not just that the dataLayer fired.

Option (a) is roughly an hour and restores the known-good setup. Option (b)
is half a day and changes work that is currently correct on the Ads side.

**Worth confirming separately: is the lead itself arriving?** The form posts
through the `/api` proxy to the frozen CMS backend, which is the right
shape, but Ted's live test of submission plus notification email was still
outstanding at launch. That should be settled before anything else here.

---

## 2. Twenty-one addresses that worked before now return 404

All verified live on 2026-10-28.

### Real pages, gone (5)

| URL | What it was | Fix |
| --- | --- | --- |
| `/how-it-works` | the How it works page | 301 to `/how-we-work`, which is the same page under a new name |
| `/blog/chatgpt-ads-shopify` | a published post | 301 to `/post-chatgpt-ads-shopify` |
| `/blog/shopify-meta-muse-ai-shopping` | a published post | 301 to `/post-shopify-meta-muse-ai-shopping` |
| `/blog/what-is-an-ai-agent` | a published post | 301 to `/post-what-is-an-ai-agent` |
| `/home` | duplicate of the homepage | 301 to `/` |

`/method` currently 301s to `/how-it-works`, so it redirects into a 404.
Fixing `/how-it-works` fixes that chain too.

The three posts matter most here: every link to a GoLumin article ever
shared, in a newsletter, a LinkedIn post or someone else's citation, is dead.

### Legacy aliases, gone (16)

These were redirect rules in the CMS. Now that the Worker answers for the
domain, the CMS never sees the request, so every rule is inert.

| From | Should go to | Hits before launch |
| --- | --- | --- |
| `/security` | `/trust` | 17 |
| `/about-us` | `/about` | 8 |
| `/platform`, `/how-lumin-works` | `/how-we-work` | 1 |
| `/jobs`, `/hiring`, `/join` | `/careers` | 1 |
| `/case-studies` | `/results` | |
| `/talk` | `/contact` | |
| `/thanks` | `/thank-you` | |
| `/ads`, `/ppc` | `/advertising` | |
| `/seo`, `/local-seo`, `/ai-search` | `/search` | |
| `/web` | `/websites` | |

**Fix for all 21: add them to the `REDIRECTS` map in `_worker.js`.** It is a
flat object; this is twenty-one lines and one deploy. Half an hour.

---

## 3. Content still published in the CMS with nowhere to land

Nothing deleted. Just not rendered.

### Four open roles are missing from the careers page

The CMS holds four published roles: Full-stack engineer, Local SEO + AI
search lead, Google Ads manager, Meta Ads manager.

`/careers` says **"Careers · 4 open roles · remote, US"** and then lists none
of them. It tells the reader to "Apply by email" without saying what for.
The roles survive only in the page's meta description, so Google still
advertises jobs the page does not show.

This is both lost content and a page contradicting itself in public. Fix: add
the four listings back to `careers.html` from the CMS entries. An hour.

### Six of seven paid landing pages

| URL | CMS title | Now |
| --- | --- | --- |
| `/lp/google-ads` | Google Ads management | rebuilt |
| `/lp/ads-audit` | Google Ads audit & second opinion | 301 to `/audit` |
| `/lp/ads` | "Free ad account audit" | 301 to `/audit` |
| `/lp/websites` | "Free website audit" | 301 to `/websites` |
| `/lp/ai-search` | "Free AI search visibility check" | 301 to `/search` |
| `/lp/chatgpt-ads` | ChatGPT & AI ads | 301 to `/programmatic-chatgpt-ads` |
| `/lp/marketing-agency` | Website, search, ads | 301 to `/` |

These do not 404, so nothing is broken for a visitor. But a redirect is not a
landing page: Google Ads scores landing page experience on where the click
lands, and `/lp/marketing-agency` sending paid traffic to the homepage is the
weakest of the six.

Three of them are titled "Free ..." in the CMS, which breaks the house rule
regardless, so their copy needs rewriting whichever way this goes.

Fix: rebuild the six in the new design, with the "Free" copy replaced. Most
of a day. Lower urgency than everything above it, because nothing 404s.

---

## 4. Client proposal links are dead

`/proposals/<slug>/<id>` returns 404 on golumin.io and 200 on
`golumin-landing.pages.dev`. Eight client proposals and two contract pages,
Drop a Box and Rachelle Doreen among them. These are the links clients open
to read and to sign.

The cause predates this relaunch: the proposals live in the Astro repo, and
golumin.io stopped pointing at that site when the domain moved.

Fix: pass `/proposals/*` through to the Pages origin in `_worker.js`,
alongside the `/api/*` proxy that is already there. Ten lines. New proposals
keep being authored as a `.ts` file in the Astro repo exactly as they are
today.

The per-proposal ids are what keep a client's pricing and contract private,
so they are deliberately not written down here. A wildcard rule does not need
them.

---

## 5. Every page tells Google a different URL than the one it is served at

24 of the 37 URLs in `sitemap.xml` are self-contradicting. The sitemap lists
`/results`; that page's canonical tag says `/work`; `/work` 301s back to
`/results`. For the three blog posts the canonical points at a 404.

This is not cosmetic. Google gets three conflicting signals per page and
resolves them by picking one or dropping the page.

Fix: rewrite the `rel="canonical"` in the 24 pages to the URL the Worker
actually serves. Mechanical, one pass, no copy changes. An hour, and it
should ship in the same deploy as the redirects so the two agree.

---

## 6. The repository is being served on the marketing domain

`wrangler.toml` sets `directory = "."` and `.assetsignore` excludes two
files, so the whole repo is public at golumin.io:

```
golumin.io/app/views/website/blocks/_home_hero.html.erb   200
golumin.io/spec/requests/website_spec.rb                  200
golumin.io/script/import.rb                               200
golumin.io/spec/fixtures/cms/snapshot.json                200   (460 KB)
```

I checked the snapshot for anything sensitive: no credentials, no tokens, no
draft content, two email addresses and one of them is marketing@golumin.io.
The repo is public on GitHub anyway, so nothing secret is exposed. It is
untidy rather than dangerous.

Fix: add `app/`, `lib/`, `config/`, `spec/`, `script/`, `*.gemspec`,
`package*.json` and `README.md` to `.assetsignore`. Five minutes, and it
makes every future deploy smaller.

---

## Suggested order

| | Fix | Why first | Effort |
| --- | --- | --- | --- |
| 1 | Confirm leads and notification emails arrive | everything else assumes the form works | Ted |
| 2 | GTM back on the pages, conversion on submit | no measurement on any channel right now | ~1 hr |
| 3 | The 21 redirects | dead links, three of them published articles | ~30 min |
| 4 | `/proposals/*` proxy | client-facing, and they are signing documents | ~15 min |
| 5 | The four job listings | a live page contradicting itself | ~1 hr |
| 6 | The 24 canonical tags | ships with 3 so the signals agree | ~1 hr |
| 7 | `.assetsignore` | tidy, rides along | ~5 min |
| 8 | Rebuild the six landing pages | nothing 404s, so it can wait | ~1 day |

Items 2 through 7 are one branch and one deploy, about half a day.

## What is already fine

The homepage, 10 case studies, 3 service pages plus 3 new ones, both team
bios, the testimonial, all 12 published clients, privacy, terms, referrals,
laspalmas, thank-you and trust all serve correctly. `robots.txt` and
`sitemap.xml` exist. The `/api` proxy to the frozen CMS form backend is
wired the right way. 31 routes smoke-tested at 200.
