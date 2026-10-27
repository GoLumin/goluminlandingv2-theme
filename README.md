# GoLumin theme

golumin.io, drawn by Libre Publish: the site's layout, a partial per block
type, the service, case-study, post and paid-landing pages, its form emails,
and its stylesheet and scripts. Plain ERB, plain CSS and an importmap; the
site serves nothing that has to be built. How themes work: Libre Publish's
docs/themes.md.

The design is the 2026 redesign, "lit from above" (the redesign's DESIGN.md):
one family, Inter; one violet accent (#5634E6); every hero a night hero, one
of the branded Lumin landscapes at full strength under an aurora of drifting
light, ending on a diagonal; white pages between; dark "night" sections for
the product, the client quote and the closing call, each with a photo too;
real client sites and the two founders instead of icons; the audit form in
the hero's right column, a marquee of client marks under it, and a call /
audit bar at the foot of the screen on a phone. No monospace, no uppercase
tracked labels, no gradient text, and never "free": the offer is an audit. The stylesheet is `script/site.src.css`:
the design is plain, unlayered CSS; Tailwind stays in the pipeline only for
the block templates that still carry utility classes (below).

The content of the redesign, and how it goes live: `script/redesign/README.md`.

## What draws what

| Address | From |
| --- | --- |
| `/`, `/services`, `/how-it-works`, `/trust`, `/work`, `/blog`, `/careers`, `/lets-talk`, `/referrals`, `/privacy`, `/terms`, `/thank-you`, `/laspalmas` | the page's blocks (`app/views/website/blocks/_<type>`) |
| `/services/<slug>` | `entries/services`: the services collection (ServicePage.astro) |
| `/work/<slug>` | `entries/work`: the case studies (work/[slug].astro) |
| `/blog/<slug>` | `entries/blog`: a post's blocks, its prose (`text`) and figures (`post_figure`) |
| `/lp/<slug>` | `entries/lp`: the paid landing pages, never indexed; `kind` service (LandingPage.astro) or adgroup (AdGroupLanding.astro) |
| anything else | the CMS's `not-found` page, with a 404 and noindex; Tools › Redirects has the Astro site's `_redirects` |
| header, footer | the `nav` and `footer` globals; Services and Results list their collections |

Lists come from collections, in their `order` field, as the Astro data files
ordered them: services (cards, nav, footer, 404), case studies (cards, logo
marquee, nav), roles (careers), clients (the "running now for" line and the
banner page's wall; drafts are the clients not cleared for public mention),
testimonials, the team. Posts are newest first. The `proof` global holds the
hero's metrics; `ad_landing` the evidence every ad-group page and the banner
page share (the offer, the plan, the badge, the click maths, the comparison,
the shared questions).

Headings mark their highlighted words in the text: `*like this*`, `_or this_`
or `^or this^` all set the words in violet (`gl_heading`).

The four forms (Forms › audit, contact, application, referral) are drawn by
hand from their fields and post to the Forms plugin; then the visitor goes to
`/thank-you?form=<slug>`, which shows that form's variant and fires
`lead_submitted` and the Google Ads and OpenAI conversions once per
submission. Each form carries the session's attribution (UTM tags, click ids,
landing page, referrer) as fields of its own. Turnstile appears when
Settings › Forms has its keys.

The theme serves its own stylesheet, scripts and images, at
`/_goluminlandingv2/<file>?v=<digest>` (`Goluminlandingv2::AssetsController`),
rather than through the asset pipeline, so it works on an install that
hasn't compiled a theme added from Settings › Plugins.

Settings › Themes › Customize: the phone number in the header, and the
phone's call / plan bar.

## The content: script/import.rb

The site had no CMS; its content was the Astro repo's data files, MDX posts
and copy in its pages. `script/import.rb` puts all of it into a Libre
Publish install — collections and their fields, block types (their fields
inferred from the content), pages, globals, forms, media with alt text,
redirects, Settings › General and Branding, the analytics tags as the
Scripts global — and is safe to run again:

    bin/rails runner themes/goluminlandingv2/script/import.rb      # ASTRO=../goluminlandingv2 by default

It reads the Astro checkout for posts and images, and `script/astro-data.json`
for the data files (`src/data/*.ts`, exported by `script/export-astro.ts`).

## Working on it

    bin/theme link ../goluminlandingv2-theme
    bin/rails runner themes/goluminlandingv2/script/import.rb   # or bin/pull from a live install
    bin/dev

    script/build-css                                            # after changing a template's classes or script/site.src.css
    bin/rspec themes/goluminlandingv2/spec                      # every page and entry, from the snapshot
    bundle exec herb lint themes/goluminlandingv2 --fail-level warning
    bin/rails goluminlandingv2:snapshot                         # refresh the snapshot from this install

`script/build-css` compiles `script/site.src.css` with Tailwind against the
theme's templates; commit the compiled `site.css` with the change. Mind that
`h-2`, `h-3` and `h-4` are Tailwind height utilities as well as the design's
heading classes: the stylesheet gives the headings `height: auto`.

`spec/fixtures/cms/snapshot.json` is the CMS's content model and live
content. The spec draws every page and entry from it, and every block type
from its defaults, so a template reading a field the CMS doesn't declare
fails here before it breaks a page.

Two things Herb's compiler gets wrong, worked around here: an `<% elsif %>`
followed by a block helper (`<%= gl_section do %>`), and `<% case %>` with
text before its first `<% when %>`. Use separate `if`s.

## Installing it

In the site's Libre Publish admin: Settings › Plugins › Add a plugin, and
give `Martin-Business-Consultants/goluminlandingv2-theme`. It installs the
latest release and restarts; the site is at `/` while the theme is switched
on and the site is served as Website (Settings › General). Publish a release
here (bump `lib/goluminlandingv2/version.rb`, tag `v0.1.0`, and a GitHub
release) and the theme's Update button takes it.

License: LICENSE.md.
