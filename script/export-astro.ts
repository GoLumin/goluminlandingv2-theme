/* The Astro site's data files (src/data/*.ts) as one JSON document,
   script/astro-data.json, which script/import.rb reads. Run from a checkout of
   the Astro site with its dependencies installed:

     cp script/export-astro.ts ../goluminlandingv2/export-astro.ts
     cd ../goluminlandingv2 && npx esbuild export-astro.ts --bundle --platform=node --format=esm --outfile=/tmp/export.mjs \
       && node /tmp/export.mjs > ../goluminlandingv2-theme/script/astro-data.json; rm export-astro.ts */
import * as services from "./src/data/services";
import * as work from "./src/data/work";
import * as proof from "./src/data/proof";
import * as guardrails from "./src/data/guardrails";
import * as landing from "./src/data/landing";
import * as adgroups from "./src/data/adgroups";
import * as laspalmas from "./src/data/laspalmas";
import * as referrals from "./src/data/referrals";
import * as roles from "./src/data/roles";
import * as site from "./src/data/site";
import * as nav from "./src/data/nav";

const plain = (m: Record<string, unknown>) => Object.fromEntries(Object.entries(m).filter(([, v]) => typeof v !== "function"));
const sharedFaqs = adgroups.faqsFor({ faqs: [] } as never);
console.log(JSON.stringify({
  services: plain(services), work: plain(work), proof: plain(proof), guardrails: plain(guardrails),
  landing: plain(landing), adgroups: { ...plain(adgroups), sharedFaqs }, laspalmas: plain(laspalmas),
  referrals: plain(referrals), roles: plain(roles), site: plain(site), nav: plain(nav),
}, null, 1));
