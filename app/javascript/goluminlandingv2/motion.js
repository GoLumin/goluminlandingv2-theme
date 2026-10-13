// Motion (motion.ts): reveal on scroll, staggered inside [data-stagger];
// magnetic buttons; parallax tilt; the elastic number bump; the spring FAQ;
// CTA click analytics.
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
const fine = matchMedia("(hover: hover) and (pointer: fine)").matches

const reveals = document.querySelectorAll(".reveal, .draw")
document.querySelectorAll("[data-stagger]").forEach((parent) => {
  Array.from(parent.children).forEach((el, i) => {
    const target = el.classList.contains("reveal") ? el : el.querySelector(".reveal")
    if (target) target.style.setProperty("--i", String(i))
  })
})
const show = (el) => {
  el.classList.add("is-visible")
  el.querySelectorAll(".bump-target").forEach((n, i) => {
    setTimeout(() => { n.classList.add("bump"); setTimeout(() => n.classList.remove("bump"), 450) }, 250 + i * 90)
  })
}
if ("IntersectionObserver" in window && !reduced) {
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) if (e.isIntersecting) { show(e.target); io.unobserve(e.target) }
  }, { rootMargin: "0px 0px -8% 0px", threshold: 0.1 })
  reveals.forEach((el) => io.observe(el))
} else {
  reveals.forEach((el) => el.classList.add("is-visible"))
}

if (fine && !reduced) {
  document.querySelectorAll(".magnet-zone").forEach((zone) => {
    const btn = zone.querySelector(".magnet")
    if (!btn) return
    zone.addEventListener("mousemove", (e) => {
      const r = btn.getBoundingClientRect()
      btn.style.setProperty("--mx", `${(e.clientX - (r.left + r.width / 2)) * 0.3}px`)
      btn.style.setProperty("--my", `${(e.clientY - (r.top + r.height / 2)) * 0.3}px`)
    })
    zone.addEventListener("mouseleave", () => { btn.style.setProperty("--mx", "0px"); btn.style.setProperty("--my", "0px") })
  })
  document.querySelectorAll(".tilt-zone").forEach((zone) => {
    const card = zone.querySelector(".tilt")
    if (!card) return
    zone.addEventListener("mousemove", (e) => {
      const r = card.getBoundingClientRect()
      const px = (e.clientX - r.left) / r.width, py = (e.clientY - r.top) / r.height
      card.style.transform = `rotateX(${(py - 0.5) * -5}deg) rotateY(${(px - 0.5) * 5}deg)`
    })
    zone.addEventListener("mouseleave", () => { card.style.transform = "" })
  })
}

document.querySelectorAll("details.faq").forEach((d) => {
  const summary = d.querySelector("summary")
  if (d.open) d.classList.add("is-open")
  summary.addEventListener("click", (e) => {
    e.preventDefault()
    if (d.classList.contains("is-open")) {
      d.classList.remove("is-open")
      const body = d.querySelector(".faq-body")
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
