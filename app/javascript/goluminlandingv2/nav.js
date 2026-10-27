// The site's bar and the page's small motions: the shadow once the page
// scrolls, the dropdown panels (hover on a pointer, click and keyboard
// everywhere), the phone's drawer, the chart bars that grow when seen, and
// the phone's call/plan bar, hidden while a form is on screen.
const nav = document.querySelector("[data-nav]")
const onScroll = () => nav?.classList.toggle("is-scrolled", window.scrollY > 8)
onScroll()
window.addEventListener("scroll", onScroll, { passive: true })

const items = document.querySelectorAll("[data-dropdown]")
const closeAll = (except) => {
  items.forEach((it) => {
    if (it === except) return
    it.classList.remove("is-open")
    it.querySelector("button")?.setAttribute("aria-expanded", "false")
  })
}
const hover = matchMedia("(hover: hover)")
items.forEach((it) => {
  const btn = it.querySelector("button")
  if (!btn) return
  btn.addEventListener("click", (e) => {
    e.stopPropagation()
    const open = it.classList.toggle("is-open")
    btn.setAttribute("aria-expanded", open ? "true" : "false")
    closeAll(it)
  })
  it.addEventListener("mouseenter", () => { if (hover.matches) { it.classList.add("is-open"); btn.setAttribute("aria-expanded", "true") } })
  it.addEventListener("mouseleave", () => { if (hover.matches) { it.classList.remove("is-open"); btn.setAttribute("aria-expanded", "false") } })
})
document.addEventListener("click", () => closeAll(null))

const toggle = document.querySelector("[data-nav-toggle]")
const drawer = document.querySelector("[data-nav-drawer]")
const closeDrawer = () => {
  if (!drawer || !toggle) return
  document.body.classList.remove("drawer-open")
  toggle.setAttribute("aria-expanded", "false")
  toggle.setAttribute("aria-label", "Open menu")
}
if (toggle && drawer) {
  toggle.addEventListener("click", () => {
    const open = document.body.classList.toggle("drawer-open")
    toggle.setAttribute("aria-expanded", open ? "true" : "false")
    toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu")
  })
  drawer.querySelectorAll("a").forEach((a) => a.addEventListener("click", closeDrawer))
}
document.addEventListener("keydown", (e) => { if (e.key === "Escape") { closeAll(null); closeDrawer() } })

// The hero's entrance: once the sequence has played, pin everything visible.
setTimeout(() => document.querySelectorAll(".hero [data-enter]").forEach((el) => el.classList.add("is-done")), 1700)

// Bars grow when seen.
const bars = document.querySelectorAll("[data-bar]")
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
const grow = (el) => { el.style.width = `${el.dataset.bar}%` }
if (bars.length) {
  if (reduced || !("IntersectionObserver" in window)) bars.forEach(grow)
  else {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => { if (e.isIntersecting) { grow(e.target); io.unobserve(e.target) } })
    }, { threshold: 0.4 })
    bars.forEach((b) => io.observe(b))
  }
}

// The phone's bar: away while a form is on screen.
const bar = document.querySelector("[data-mobile-bar]")
const forms = document.querySelectorAll(".form-card")
if (bar && forms.length && "IntersectionObserver" in window) {
  const visible = new Set()
  const io = new IntersectionObserver((entries) => {
    entries.forEach((e) => { e.isIntersecting ? visible.add(e.target) : visible.delete(e.target) })
    bar.classList.toggle("is-hidden", visible.size > 0)
  }, { threshold: 0.15 })
  forms.forEach((f) => io.observe(f))
}
