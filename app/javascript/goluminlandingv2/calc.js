// The referral calculator (ReferralCalc.astro): the visitor's numbers in,
// what a referral pays out. One analytics event, once they've moved something.
const root = document.querySelector("[data-referral-calc]")
if (root) {
  const rate = Number(root.dataset.rate)
  const months = Number(root.dataset.months)
  const credit = Number(root.dataset.credit)
  const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 })
  const set = (key, value) => { const el = root.querySelector(`[data-out="${key}"]`); if (el) el.textContent = fmt.format(value) }
  const build = root.querySelector('[data-slider="build"]')
  const monthly = root.querySelector('[data-slider="monthly"]')
  const render = () => {
    const b = Number(build?.value || 0)
    const m = Number(monthly?.value || 0)
    const onetime = (b * rate) / 100
    const recurring = (m * months * rate) / 100
    set("build", b); set("monthly", m); set("onetime", onetime); set("recurring", recurring)
    set("total", onetime + recurring); set("credit", (onetime + recurring) * credit)
  }
  let reported = false
  const onInput = () => {
    render()
    if (reported) return
    reported = true
    window.dataLayer?.push({ event: "use_referral_calculator" })
  }
  build?.addEventListener("input", onInput)
  monthly?.addEventListener("input", onInput)
  render()
}
