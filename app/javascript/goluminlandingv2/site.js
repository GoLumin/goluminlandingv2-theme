// The website's entry point: the site's behaviours, each a module of its own,
// and the few things every page does (attribution, analytics events, the
// landing pages' headline variants, the thank-you page's variant).
import "goluminlandingv2/attribution"
import "goluminlandingv2/motion"
import "goluminlandingv2/forms"
import "goluminlandingv2/video"
import "goluminlandingv2/metrics"
import "goluminlandingv2/calc"
import "goluminlandingv2/figures"

const push = (data) => { window.dataLayer = window.dataLayer || []; window.dataLayer.push(data) }

// Message match on the landing pages: ?v=<key> swaps the headline (and standfirst).
const variants = document.querySelector("[data-gl-variants]")
let landingVariant = "default"
if (variants) {
  try {
    const v = new URLSearchParams(location.search).get("v")
    const all = JSON.parse(variants.dataset.glVariants || "{}")
    const hit = v && Object.prototype.hasOwnProperty.call(all, v) ? all[v] : null
    if (hit) {
      landingVariant = v
      document.querySelector("[data-lp-h1]").textContent = hit.h[0]
      document.querySelector("[data-lp-h2]").textContent = hit.h[1]
      if (hit.sub) document.querySelector("[data-lp-sub]").textContent = hit.sub
    }
  } catch {}
}

// A page's analytics event (view_service, view_case_study, view_landing).
document.querySelectorAll("[data-gl-event]").forEach((el) => {
  try {
    const event = JSON.parse(el.dataset.glEvent)
    if (event.event === "view_landing") event.landing_variant = landingVariant
    push(event)
  } catch {}
})

// The thank-you page: the variant for the form that was sent (?form=<slug>),
// then one lead_submitted per accepted lead (?lead=<id>), with the Google Ads
// and OpenAI conversions, never twice for the same lead.
const confirmations = document.querySelectorAll("[data-variant]")
if (confirmations.length) {
  try {
    const params = new URLSearchParams(location.search)
    const form = params.get("form") || ""
    const match = Array.from(confirmations).find((el) => el.dataset.form && el.dataset.form === form)
    if (match) {
      confirmations.forEach((el) => { el.hidden = el !== match })
      document.title = `${match.dataset.title} · GoLumin`
    }
    const back = params.get("back")
    if (back && /^\/[A-Za-z0-9\-._~/]*$/.test(back) && !back.startsWith("//")) document.querySelectorAll("[data-back]").forEach((a) => { a.href = back })
    const leadId = params.get("lead")
    if (leadId) {
      history.replaceState(null, "", location.pathname)
      let seen = []
      try { seen = JSON.parse(localStorage.getItem("lumin_leads") || "[]") } catch {}
      if (!seen.includes(leadId)) {
        push({ event: "lead_submitted", lead_id: leadId, form_location: form || "unknown" })
        try { window.gtag?.("event", "conversion", { send_to: "AW-18424158289/mTzKCPb8uvUcENGwqdFE", transaction_id: leadId }) } catch {}
        try { window.oaiq?.("measure", "subscription_created", { type: "plan_enrollment" }) } catch {}
        try { localStorage.setItem("lumin_leads", JSON.stringify(seen.concat(leadId).slice(-20))) } catch {}
      }
    }
  } catch {}
}

// The 404: which dead addresses people reach, and what sent them.
if (document.querySelector("[data-not-found]")) {
  push({ event: "page_not_found", missing_path: location.pathname + location.search, missing_referrer: document.referrer || "(none)" })
}

// view_human_gate: did the visitor reach the approval model, or leave before it?
const gate = document.querySelector("[data-human-gate]")
if (gate && "IntersectionObserver" in window) {
  const io = new IntersectionObserver(([e]) => { if (!e.isIntersecting) return; io.disconnect(); push({ event: "view_human_gate" }) }, { threshold: 0.4 })
  io.observe(gate)
}
