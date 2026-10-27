# The redesign's content

The copy of the 2026 redesign ("lit from above"), as the CMS holds it, kept
here so the launch is a set of known steps rather than a retype.

| File | What it is |
| --- | --- |
| `build.py` | Writes `pages/*.json`, `globals.json` and `services.json` from the redesign's copy (v3: audits, never "free"). |
| `pages/*.json` | One CMS page per redesign page, as blocks of the existing block types. Posted to the live CMS as drafts named `redesign-<slug>` (held for approval first, as every agent write is there). |
| `globals.json` | The `nav` and `footer` globals, and the `ad_landing` global's `founders` group, as the redesign wants them. Globals have no draft state, so these are **not** written to the live CMS: apply them at launch. |
| `entries/<slug>.json` | The three service entries' new fields (headline, standfirst, card copy, cases, FAQs, the audit button), as a body for `cms patch /collections/services/entries/<slug> - < entries/<slug>.json`. The fields not listed keep their live values. Not filed from the agent session: a write to a published entry was refused by its permission mode, so a person runs the three patches (the CMS holds them for approval). |
| `services.json` | The services collection's card copy (`nav`, `promise`, `capabilities`, `proof`, `cases`) as the redesign's service cards say it. The entries are published, so these are not written to the live CMS either: apply at launch. A card's picture is its first case study's homepage: Advertising wants the new BioFuse screenshot (replace asset 25's file with the redesign's `work-biofuse.webp`), Getting found wants Kalamazoo Rejuvenation, which needs a `work` entry (title, host, screenshot from the redesign's `work-kalamazoo-rejuvenation.webp`, a logo if there is one) before it can show. |

## Where each page is meant to live

Hard rule: no live URL changes. No renamed paths, no new paths for pages that already exist, no redirects as a substitute. The only new paths are pages that do not exist today, `/tracking` and `/about`.

| Draft | Goes onto | How |
| --- | --- | --- |
| redesign-home | `/` (the `home` page) | copy the draft's blocks onto the live page |
| redesign-services | `/services` | copy the blocks onto the live page |
| redesign-websites, redesign-advertising, redesign-search | the service entries at `/services/websites`, `/services/advertising`, `/services/local-ai-search` | the entries' fields (`services.json`, and the proposals filed against each entry); the service page template draws them. The drafts' stat rows and feature rows have no field on an entry and stay in the repo unless the services collection gets blocks |
| redesign-tracking | `/tracking` | new page: rename the draft (slug `tracking`) and publish |
| redesign-results | `/work` | copy the blocks onto the live page |
| redesign-how-we-work | `/how-it-works` | copy the blocks onto the live page. `/trust` stays live as its own page: its existing blocks already render in the new layout; leave its copy |
| redesign-about | `/about` | new page: rename the draft (slug `about`) and publish |
| redesign-contact | `/lets-talk` | copy the blocks onto the live page |
| redesign-careers, redesign-referrals | `/careers`, `/referrals` | copy the blocks onto the live pages (their roles, calculator and forms are kept) |
| `/privacy`, `/terms`, `/blog`, `/lp/*`, `/work/*` | unchanged | keep their content; the templates draw the new layout |

Every internal link in the drafts, the nav and the footer already points at these live paths ("How we work" → `/how-it-works`, "Trust & approvals" → `/trust`, "Let's talk" → `/lets-talk`, "Local & AI search" → `/services/local-ai-search`, the Tracking link → `/tracking`, Company → `/about`). No redirects are needed.

## Also at launch, in published entries

- The paid landing pages (`lp` entries) keep their own copy. Bring them in line with v3: `submit_label` "Request my audit", no "free" in `h`, `sub`, `checks`, `pains` or `faqs` (the Google Ads page's "Is the free landing page really free?" becomes "Is the landing page included?"), and SEO titles without "Free".
- The `ad_landing` global's `plan` group (`globals.json`, key `ad_landing.plan`) and its `offer` group still say "free": apply the plan from `globals.json` and reword the offer.
- The `laspalmas` page's banner copy and the thank-you page's variants mention the free plan; reword by hand.

## The client marquee

The marquee under the hero draws every case study with a logo, then every other published client (the `clients` collection) as a wordmark. Jordan asked for Tru-Colors Contracting to come off it: its client entry (`tru-colors-contracting`) is in draft on the live CMS, and a draft client is one not cleared for public mention, so the marquee leaves it out. Keep it that way.

## The phone number

The number is (415) 283-6736 (tel:+14152836736). The theme reads it from Settings › General › phone (`gl_phone`), with the new number as its fallback; the header, the phone drawer, the call / audit bar, every form's "Rather talk?" line and the landing bar all take it from there. Set it in Settings › General at launch. The footer global's phone item is in `globals.json`; the drafts' closing calls, the home hero's call button and the contact cards carry it in their own copy.

## Launching

1. Approve the held creates (Approvals), so the drafts exist: one per `redesign-*` slug, the newest proposal for each (older proposals for the same slug carry superseded copy and should be rejected).
2. Release the theme (`lib/goluminlandingv2/version.rb`, tag, GitHub release) and update it on the site (Settings › Themes).
3. Copy each draft's blocks onto the live page it replaces (never rename a live page); rename only `redesign-tracking` and `redesign-about`, the two new pages; publish.
4. Apply `globals.json` to the `nav`, `footer` and `ad_landing` globals, and `services.json` to the three service entries.
6. Trash the `redesign-*` drafts.

Blog posts, the privacy policy and the terms keep their content and take the new layout.
