// Attribution, captured once per session so every form carries it (Base.astro).
// First of the site's modules, so a form on the landing page itself has it.
try {
  const params = new URLSearchParams(location.search)
  const keys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid", "msclkid", "v"]
  const got = {}
  keys.forEach((k) => { const x = params.get(k); if (x) got[k] = x })
  if (Object.keys(got).length) {
    const prev = JSON.parse(sessionStorage.getItem("lumin_attr") || "{}")
    if (!prev.landing_path) got.landing_path = location.pathname + location.search
    if (!prev.referrer) got.referrer = document.referrer || ""
    sessionStorage.setItem("lumin_attr", JSON.stringify(Object.assign(prev, got)))
  } else if (!sessionStorage.getItem("lumin_attr")) {
    sessionStorage.setItem("lumin_attr", JSON.stringify({ landing_path: location.pathname, referrer: document.referrer || "" }))
  }
} catch {}
