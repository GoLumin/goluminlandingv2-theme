# Redirect map for the golumin.io relaunch

**Status: proposal. Nothing here is implemented.** Step 1 of the launch plan:
produce the mapping, get Jordan's sign-off, then build it.

Sources of truth used to build this, all read on 2026-10-27:

- the 39 pages on `design/golumin-live-site` (commit `a1d3577`), and the
  `rel="canonical"` each one declares
- golumin.io's live routes, from the CMS: 15 published pages, 3 services,
  10 case studies, 3 posts, 7 paid landing pages
- the 23 redirect rules already in the CMS (Tools > Redirects), with hit counts
- the staging worker, probed for what it serves today

---

## The one decision that drives everything else

Every page on the new site already declares the URL it wants, and that URL is
**golumin.io's live URL**, not its own filename:

| File | Staging serves it at | Its canonical tag says |
| --- | --- | --- |
| `results.html` | `/results` | `/work` |
| `contact.html` | `/contact` | `/lets-talk` |
| `advertising.html` | `/advertising` | `/services/advertising` |
| `case-biofuse.html` | `/case-biofuse` | `/work/biofuse` |
| `post-what-is-an-ai-agent.html` | `/post-what-is-an-ai-agent` | `/blog/what-is-an-ai-agent` |

22 of the 39 pages disagree with themselves this way. Right now staging tells
Google "this page lives at /work" while serving it at /results, and `/work`
itself returns 404 there.

**Recommendation: serve the canonical URLs.** `/work`, `/services/advertising`,
`/work/biofuse`, `/blog/what-is-an-ai-agent`, `/lets-talk`. The flat filenames
301 to them.

Three reasons:

1. **It is the no-404 rule, satisfied for free.** Every live golumin.io URL
   keeps working at the same address. Nothing to redirect, no ranking to
   reassign, no inbound link to chase.
2. **The 23 redirects already in the CMS agree with it.** `/results` already
   301s to `/work` today. `/contact` already 301s to `/lets-talk` (83 hits).
   `/advertising`, `/search`, `/websites` already point into `/services/*`.
   Serving the filenames instead would mean reversing rules that are already
   live and already being followed.
3. **The pages' own canonical tags already say so.** No HTML has to change.

The alternative, serving the flat filenames, would move 36 live URLs at once
and reverse 11 existing redirects. I do not recommend it.

Everything below assumes the recommendation. Say the word if you want the other
shape and I will redraw it.

---

## 1. Live golumin.io URLs, and where each one lands

No live URL moves. 36 of 37 are served by a file on the new branch at the same
address.

### Pages

| Live URL | Served by | Note |
| --- | --- | --- |
| `/` | `index.html` | |
| `/home` | -> 301 `/` | live 200 today, duplicate of `/`; fold it in |
| `/services` | `services.html` | |
| `/how-it-works` | `how-we-work.html` | |
| `/trust` | `trust.html` | |
| `/work` | `results.html` | |
| `/careers` | `careers.html` | |
| `/lets-talk` | `contact.html` | |
| `/blog` | `blog.html` | |
| `/referrals` | `referrals.html` | |
| `/laspalmas` | `laspalmas.html` | |
| `/thank-you` | `thank-you.html` | the form's destination |
| `/privacy` | `privacy.html` | |
| `/terms` | `terms.html` | |
| `/claude-access-test` | `claude-access-test.html` | |

### Services

| Live URL | Served by |
| --- | --- |
| `/services/websites` | `websites.html` |
| `/services/local-ai-search` | `search.html` |
| `/services/advertising` | `advertising.html` |

### Case studies, all ten

| Live URL | Served by |
| --- | --- |
| `/work/mulebox` | `case-mulebox.html` |
| `/work/foxbox-moves` | `case-foxbox-moves.html` |
| `/work/inbox-portable-storage` | `case-inbox-portable-storage.html` |
| `/work/kalamazoo-mortgage` | `case-kalamazoo-mortgage.html` |
| `/work/the-foundry` | `case-the-foundry.html` |
| `/work/wise-insurance` | `case-wise-insurance.html` |
| `/work/white-and-white` | `case-white-and-white.html` |
| `/work/shine-learning-alliance` | `case-shine-learning-alliance.html` |
| `/work/biofuse` | `case-biofuse.html` |
| `/work/behnke-logistics` | `case-behnke-logistics.html` |

### Posts, all three

| Live URL | Served by |
| --- | --- |
| `/blog/chatgpt-ads-shopify` | `post-chatgpt-ads-shopify.html` |
| `/blog/shopify-meta-muse-ai-shopping` | `post-shopify-meta-muse-ai-shopping.html` |
| `/blog/what-is-an-ai-agent` | `post-what-is-an-ai-agent.html` |

### Paid landing pages: one of seven exists. **This needs your call.**

| Live URL | CMS title | New site |
| --- | --- | --- |
| `/lp/google-ads` | Google Ads management | `lp-google-ads.html` |
| `/lp/ads-audit` | Google Ads audit & second opinion | **missing** |
| `/lp/chatgpt-ads` | ChatGPT & AI ads | **missing** |
| `/lp/marketing-agency` | Website, search, ads | **missing** |
| `/lp/websites` | "Free website audit" | **missing** |
| `/lp/ai-search` | "Free AI search visibility check" | **missing** |
| `/lp/ads` | "Free ad account audit" | **missing** |

All seven return 200 on golumin.io right now, and these are the pages paid
traffic lands on. A 404 here is spend going in the bin, so this is the single
highest-risk gap in the launch.

Two ways to close it:

- **(a) Interim 301s, launch on schedule.** Point the six at the nearest
  matching new page. My proposal:
  `/lp/ads-audit`, `/lp/ads`, `/lp/websites`, `/lp/ai-search` -> `/audit`;
  `/lp/chatgpt-ads` -> `/services/programmatic-chatgpt-ads`;
  `/lp/marketing-agency` -> `/services`.
  Cheap and safe against 404s, but Google Ads scores landing page experience on
  the page the click actually reaches, so expect some Quality Score drift.
- **(b) Rebuild the six in the new design before launch.** Cleanest. Three of
  the six are named "Free ..." in the CMS, so their copy needs rewriting
  regardless of which design ships.

Separately: these pages are `noindex`, so there is no SEO equity at stake,
only live ad traffic.

---

## 2. The 23 redirects already in the CMS

21 carry over unchanged. Two conflict with the new site and need a decision.

### Carry over as-is

| From | To | Hits |
| --- | --- | --- |
| `/thanks` | `/thank-you` | 0 |
| `/websites` | `/services/websites` | 0 |
| `/website` | `/services/websites` | 2 |
| `/web` | `/services/websites` | 0 |
| `/advertising` | `/services/advertising` | 0 |
| `/ads` | `/services/advertising` | 0 |
| `/ppc` | `/services/advertising` | 0 |
| `/search` | `/services/local-ai-search` | 6 |
| `/seo` | `/services/local-ai-search` | 0 |
| `/local-seo` | `/services/local-ai-search` | 0 |
| `/ai-search` | `/services/local-ai-search` | 0 |
| `/platform` | `/how-it-works` | 1 |
| `/how-lumin-works` | `/how-it-works` | 0 |
| `/case-studies` | `/work` | 0 |
| `/results` | `/work` | 0 |
| `/security` | `/trust` | 17 |
| `/contact` | `/lets-talk` | 83 |
| `/talk` | `/lets-talk` | 0 |
| `/jobs` | `/careers` | 1 |
| `/hiring` | `/careers` | 0 |
| `/join` | `/careers` | 0 |

### Conflicts

| Rule | Hits | Problem | Proposed |
| --- | --- | --- | --- |
| `/about` -> `/` | 26 | the new site has a real `/about` page, "Who you'll work with" | **delete the rule**, serve the page |
| `/about-us` -> `/` | 8 | same | **repoint to `/about`** |

---

## 3. Flat filename -> canonical, 301

These are not live URLs; they are the paths staging serves today, so anything
already shared from staging keeps working.

| From | To |
| --- | --- |
| `/results` | `/work` |
| `/contact` | `/lets-talk` |
| `/how-we-work` | `/how-it-works` |
| `/advertising` | `/services/advertising` |
| `/search` | `/services/local-ai-search` |
| `/websites` | `/services/websites` |
| `/website` | `/services/websites` |
| `/google-ads` | `/services/google-ads` |
| `/meta-ads` | `/services/meta-ads` |
| `/programmatic-chatgpt-ads` | `/services/programmatic-chatgpt-ads` |
| `/case-<slug>` (x10) | `/work/<slug>` |
| `/post-<slug>` (x3) | `/blog/<slug>` |
| `/lp-google-ads` | `/lp/google-ads` |
| `/index` | `/` |
| any `*.html` | the same path without `.html` |

The 1,900-odd internal `href="foo.html"` links in the pages should be rewritten
to the canonical paths at the same time, so a visitor clicking the nav does not
eat a 301 on every page. Mechanical, and part of step 2, not a content change.

---

## 4. New routes, live nowhere today

Nothing to redirect. Listed so they make it into `sitemap.xml` in step 3.

| New URL | Page |
| --- | --- |
| `/audit` | The marketing audit |
| `/about` | Who you'll work with |
| `/tracking` | Tracking & integrations |
| `/services/google-ads` | Google Ads management |
| `/services/meta-ads` | Meta & social ads |
| `/services/programmatic-chatgpt-ads` | Programmatic & ChatGPT ads |
| `/404` | Page not found, served on any unmatched path |

`/audit` is the busiest destination on the new site: 183 internal links point
at it.

---

## 5. Two loose ends found while mapping

- **`website.html` is a stale duplicate of `websites.html`.** Same canonical,
  same page, but it is missing the four highlighted phrases the finished one
  has, and nothing links to it. Proposed: delete it. `/website` keeps its
  existing 301 to `/services/websites`.
- **`claude-access-test.html`** is live on golumin.io and carried over. It
  looks like a leftover probe page. Say the word and it goes, with a 301 to `/`.

## What I checked and did not find

No uses of "free", no em dashes, and (415) 283-6736 on all 225 phone links
across the 39 pages. The three "Free ..." titles above are in the CMS's landing
page entries, not on this branch.

## Counts

| | |
| --- | --- |
| Live golumin.io URLs | 37 |
| Covered by a page at the same address | 31 |
| Covered by a new 301 | 1 (`/home`) |
| **Not covered, needs your call** | **6** (the `/lp/*` pages) |
| Existing CMS redirects carried over | 21 of 23 |
| Existing CMS redirects to change | 2 (`/about`, `/about-us`) |
| New 301s, filename to canonical | 29 |
| New routes with no live counterpart | 7 |
