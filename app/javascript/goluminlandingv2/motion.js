// Motion: reveal on scroll, staggered inside [data-stagger]; the number bump;
// the FAQ that springs open in place; CTA click analytics. Quiet, and off
// entirely for anyone who asked for reduced motion.
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches

// Two reveal protocols: the Method templates mark elements with
// [data-reveal] and the CSS waits for .in; older partials use .reveal/.draw
// and wait for .is-visible. One observer serves both.
const reveals = document.querySelectorAll(".reveal, .draw, [data-reveal]")
document.querySelectorAll("[data-stagger]").forEach((parent) => {
  Array.from(parent.children).forEach((el, i) => {
    const target = el.classList.contains("reveal") ? el : el.querySelector(".reveal")
    if (target) target.style.setProperty("--i", String(Math.min(i, 5)))
  })
})
const show = (el) => {
  if (el.classList.contains("in")) return
  el.classList.add("is-visible", "in")
  el.querySelectorAll(".bump-target").forEach((n, i) => {
    setTimeout(() => { n.classList.add("bump"); setTimeout(() => n.classList.remove("bump"), 450) }, 250 + i * 90)
  })
}
if ("IntersectionObserver" in window && !reduced) {
  const io = new IntersectionObserver((entries) => {
    // Reveal on intersect, and also anything already above the viewport:
    // anchor jumps and restored scroll positions land past elements the
    // observer would otherwise leave hidden forever.
    for (const e of entries) if (e.isIntersecting || e.boundingClientRect.bottom < 0) { show(e.target); io.unobserve(e.target) }
  }, { rootMargin: "0px 0px -6% 0px", threshold: 0 })
  reveals.forEach((el) => io.observe(el))
  // Safety sweep on bfcache restores: reveal whatever sits at or above the view.
  addEventListener("pageshow", () => {
    reveals.forEach((el) => { if (el.getBoundingClientRect().top < innerHeight) show(el) })
  })
} else {
  reveals.forEach((el) => show(el))
}

// The FAQ: the answer's grid row grows and shrinks (a <details> can't animate on its own).
document.querySelectorAll("details.faq").forEach((d) => {
  const summary = d.querySelector("summary")
  const body = d.querySelector(".faq-body")
  if (!summary || !body) return
  if (d.open) d.classList.add("is-open")
  summary.addEventListener("click", (e) => {
    e.preventDefault()
    if (d.classList.contains("is-open")) {
      d.classList.remove("is-open")
      const done = () => { d.open = false; body.removeEventListener("transitionend", done) }
      reduced ? (d.open = false) : body.addEventListener("transitionend", done)
    } else {
      d.open = true
      requestAnimationFrame(() => requestAnimationFrame(() => d.classList.add("is-open")))
    }
  })
})

document.querySelectorAll("[data-cta]").forEach((a) => {
  a.addEventListener("click", () => { window.dataLayer?.push({ event: "cta_click", cta_location: a.dataset.cta }) })
})
