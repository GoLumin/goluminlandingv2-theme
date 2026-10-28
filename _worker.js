// golumin.io launch worker: serves the approved static site, proxies the
// form API to the CMS (frozen backend untouched), and 301s every legacy
// URL so nothing that was live ever 404s.
const CMS_ORIGIN = "https://cms-golumin-production-bbbaed.178-156-207-9.sslip.io";

const REDIRECTS = {
  "/method": "/how-it-works",
  "/lets-talk": "/contact",
  "/work": "/results",
  "/work/behnke-logistics": "/case-behnke-logistics",
  "/work/biofuse": "/case-biofuse",
  "/work/foxbox-moves": "/case-foxbox-moves",
  "/work/inbox-portable-storage": "/case-inbox-portable-storage",
  "/work/kalamazoo-mortgage": "/case-kalamazoo-mortgage",
  "/work/mulebox": "/case-mulebox",
  "/work/shine-learning-alliance": "/case-shine-learning-alliance",
  "/work/the-foundry": "/case-the-foundry",
  "/work/white-and-white": "/case-white-and-white",
  "/work/wise-insurance": "/case-wise-insurance",
  "/services/websites": "/websites",
  "/services/advertising": "/advertising",
  "/services/local-ai-search": "/search",
  "/lp/google-ads": "/lp-google-ads",
  "/lp/ads": "/audit",
  "/lp/ads-audit": "/audit",
  "/lp/ai-search": "/search",
  "/lp/chatgpt-ads": "/programmatic-chatgpt-ads",
  "/lp/marketing-agency": "/",
  "/lp/websites": "/websites",
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    const target = REDIRECTS[path];
    if (target) return Response.redirect(new URL(target, url.origin).toString(), 301);

    if (url.pathname.startsWith("/api/")) {
      const upstream = new Request(CMS_ORIGIN + url.pathname + url.search, request);
      return fetch(upstream);
    }

    return env.ASSETS.fetch(request);
  },
};
