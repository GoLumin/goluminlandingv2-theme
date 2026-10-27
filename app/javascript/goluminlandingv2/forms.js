// Every form the theme draws (audit, contact, application, referral; the
// Astro site's lead-forms.ts): Turnstile loaded on first sight of a form,
// the session's attribution replayed into it, validation that ignores fields
// hidden by its routing, the audit type kept in step across the page's
// forms, the posting to the Forms plugin, then on to /thank-you. Also the
// phone's sticky audit bar.
const forms = document.querySelectorAll("form[data-audit-form]")
const push = (event, data = {}) => window.dataLayer?.push({ event, ...data })
const SPEND_TYPES = ["Full system (web + search + ads)", "Ad account"]
const KINDS = { application: "application", referral: "referral" }

// Turnstile: Cloudflare's script on first need, one widget per form.
const tokens = new WeakMap()
const widgets = new WeakMap()
const rendered = new WeakSet()
let scriptLoading = null
const loadTurnstile = () => (scriptLoading ??= new Promise((resolve) => {
  if (window.turnstile) return resolve()
  const s = document.createElement("script")
  s.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
  s.async = true
  s.onload = () => resolve()
  document.head.appendChild(s)
}))
const refresh = (form) => { const id = widgets.get(form); if (id) window.turnstile?.reset(id) }
const mountTurnstile = async (form) => {
  const el = form.querySelector("[data-turnstile]")
  if (!el || !el.dataset.sitekey) return
  if (rendered.has(form)) { if (!tokens.get(form)) refresh(form); return }
  rendered.add(form)
  await loadTurnstile()
  const id = window.turnstile?.render(el, {
    sitekey: el.dataset.sitekey, appearance: "always",
    callback: (t) => tokens.set(form, t),
    "expired-callback": () => { tokens.delete(form); refresh(form) },
    "error-callback": () => tokens.delete(form)
  })
  if (id) widgets.set(form, id)
}

// A field that failed: its .field wrapper carries the red ring (site.css).
const mark = (field, bad) => { if (!field) return; (field.closest(".field") || field).classList.toggle("is-invalid", bad) }

const MESSAGES = {
  captcha_failed: "We couldn't verify you're human. Please try again.",
  rate_limited: "That's a lot of tries in a short time. Please wait a few minutes and send it again.",
  not_found: "This form isn't taking answers right now. Please call us instead."
}

if (forms.length) {
  let started = false

  // "Audit my website" links carry the service across to the form.
  document.addEventListener("click", (e) => {
    const wanted = e.target.closest?.("[data-audit-preselect]")?.dataset.auditPreselect
    if (wanted) forms.forEach((f) => f.dispatchEvent(new CustomEvent("lumin:audit-type", { detail: wanted })))
  })

  const io = "IntersectionObserver" in window
    ? new IntersectionObserver((entries, obs) => {
      for (const e of entries) { if (!e.isIntersecting) continue; obs.unobserve(e.target); mountTurnstile(e.target) }
    }, { rootMargin: "200px" })
    : null

  forms.forEach((form) => {
    const slug = form.dataset.formSlug
    const kind = KINDS[slug] || "audit"
    if (io) io.observe(form)
    else form.addEventListener("focusin", () => mountTurnstile(form), { once: true })

    try {
      const attr = JSON.parse(sessionStorage.getItem("lumin_attr") || "{}")
      for (const [k, v] of Object.entries(attr)) {
        const el = form.querySelector(`input[type="hidden"][name="${k}"]`)
        if (el) el.value = String(v)
      }
    } catch {}

    // The spend question only when the audit involves paid media; every form on the page in step.
    const type = form.querySelector("[data-audit-type]")
    const spendField = form.querySelector("[data-spend-field]")
    const spend = form.querySelector("[data-spend]")
    const applyType = (value, notify) => {
      if (!type) return
      if (type.tagName === "SELECT" && type.value !== value) type.value = value
      const relevant = SPEND_TYPES.includes(type.value)
      if (spendField) spendField.hidden = !relevant
      if (spend) { spend.required = relevant; if (!relevant) mark(spend, false) }
      if (notify) push("select_audit_type", { audit_type: value })
    }
    type?.addEventListener("change", () => {
      applyType(type.value, true)
      forms.forEach((other) => { if (other !== form) other.dispatchEvent(new CustomEvent("lumin:audit-type", { detail: type.value })) })
    })
    form.addEventListener("lumin:audit-type", (e) => applyType(e.detail, false))

    // A referrer who wants the programme first isn't asked for a contact.
    const referralType = form.querySelector("[data-referral-type]")
    if (referralType) {
      const blocks = Array.from(form.querySelectorAll("[data-referral-field]"))
      const required = blocks.flatMap((b) => Array.from(b.querySelectorAll("[required]")))
      const applyReferralType = (notify) => {
        const naming = referralType.value === "Referral"
        blocks.forEach((b) => { b.hidden = !naming })
        required.forEach((f) => { f.required = naming; if (!naming) mark(f, false) })
        if (notify) push("select_referral_type", { referral_type: referralType.value })
      }
      referralType.addEventListener("change", () => applyReferralType(true))
      applyReferralType(false)
    }

    form.addEventListener("input", (e) => {
      mark(e.target, false)
      if (started) return
      started = true
      push("form_start")
      if (kind === "application") push("start_application")
      else if (kind === "referral") push("start_referral")
      else push("start_audit", { audit_type: type?.value })
    })

    form.addEventListener("submit", async (e) => {
      e.preventDefault()
      const err = form.querySelector("[data-error]")
      const btn = form.querySelector("[data-submit]")
      const say = (text) => { err.textContent = text; err.hidden = false }
      err.hidden = true
      const missing = Array.from(form.querySelectorAll("[required]")).filter((f) => !f.closest("[hidden]") && !f.value.trim())
      const emailEl = form.querySelector("[data-email]")
      const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim())
      if (missing.length || !emailOk) {
        say(missing.length ? "Please fill in the highlighted fields." : "That email address doesn't look right.")
        missing.forEach((f) => mark(f, true))
        if (!emailOk) mark(emailEl, true)
        ;(missing[0] || emailEl).scrollIntoView({ block: "center", behavior: "smooth" })
        return
      }
      if (btn.disabled) return
      const ts = form.querySelector("[data-turnstile]")
      if (ts?.dataset.sitekey && !tokens.get(form)) {
        await mountTurnstile(form)
        say("One moment while we check you're human, then press the button again.")
        return
      }
      const label = btn.textContent
      btn.disabled = true
      btn.textContent = "Sending…"
      push("form_submit")
      if (kind === "application") push("submit_application", { role: form.querySelector('[name="role"]')?.value })
      else if (kind === "referral") push("submit_referral", { referral_type: form.querySelector('[name="referral_type"]')?.value })
      else push("submit_audit", { audit_type: type?.value })

      // Fields hidden by routing aren't sent.
      const data = new FormData(form)
      form.querySelectorAll("[hidden] [name]").forEach((f) => data.delete(f.name))
      try {
        const response = await fetch(form.action, { method: "POST", body: data, headers: { Accept: "application/json" } })
        const body = await response.json().catch(() => ({}))
        if (response.ok) {
          const next = new URLSearchParams({ form: slug, back: location.pathname })
          if (body.id) next.set("lead", String(body.id))
          location.href = `/thank-you?${next}`
          return
        }
        Object.keys(body.errors || {}).forEach((name) => mark(form.querySelector(`[name="${CSS.escape(name)}"]`), true))
        say(MESSAGES[body.error] || (body.errors ? "Something didn't look right. Please check the highlighted fields and try again." : "We couldn't reach the server. Please try again, or give us a call."))
      } catch {
        say("We couldn't reach the server. Please try again, or give us a call.")
      }
      btn.disabled = false
      btn.textContent = label
      tokens.delete(form)
      refresh(form)
    })
  })
}
