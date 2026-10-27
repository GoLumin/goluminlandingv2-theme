# The redesign's content

The copy of the 2026 redesign ("lit from above"), as the CMS holds it, kept
here so the launch is a set of known steps rather than a retype.

| File | What it is |
| --- | --- |
| `pages/*.json` | One CMS page per redesign page, as blocks of the existing block types. Posted to the live CMS as drafts named `redesign-<slug>` (held for approval first, as every agent write is there). |
| `globals.json` | The `nav` and `footer` globals, and the `ad_landing` global's `founders` group, as the redesign wants them. Globals have no draft state, so these are **not** written to the live CMS: apply them at launch. |
| `services.json` | The services collection's card copy (`nav`, `promise`, `capabilities`, `proof`, `cases`) as the redesign's service cards say it. The entries are published, so these are not written to the live CMS either: apply at launch. |
| `redirects.json` | The redirects to add if a draft takes a new path at launch. |

## Where each page is meant to live

| Draft | Final path | Replaces |
| --- | --- | --- |
| redesign-home | `/` | the home page's blocks |
| redesign-services | `/services` | the services page's blocks |
| redesign-websites, redesign-advertising, redesign-search | `/websites`, `/advertising`, `/search`, or fold the copy into the services entries, whose pages at `/services/<slug>` already render in the new design | new |
| redesign-tracking | `/tracking` | new |
| redesign-results | `/work` | the results page's blocks |
| redesign-how-we-work | `/how-it-works` (or `/how-we-work` with a redirect) | how-it-works and trust |
| redesign-about | `/about` | new |
| redesign-contact | `/lets-talk` | the let's-talk page's blocks |
| redesign-careers, redesign-referrals | `/careers`, `/referrals` | those pages' blocks (their roles, calculator and forms are kept) |

Links inside the drafts already point at the final paths above.

## Launching

1. Approve the held creates (Approvals), so the drafts exist.
2. Release the theme (`lib/goluminlandingv2/version.rb`, tag, GitHub release) and update it on the site (Settings › Themes).
3. Copy each draft's blocks onto the live page it replaces (or rename the draft to the final path and trash the old page), and publish.
4. Apply `globals.json` to the `nav`, `footer` and `ad_landing` globals, and `services.json` to the three service entries.
5. Add the redirects in `redirects.json` that apply.
6. Trash the `redesign-*` drafts.

Blog posts, the privacy policy and the terms keep their content and take the new layout.
