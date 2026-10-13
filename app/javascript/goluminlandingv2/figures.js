// A post's figures (post-motion.ts), with the browser's own animations: each
// one plays once as it scrolls into view. Every animation runs from a start
// keyframe to where the stylesheet already put the element, so without
// script, or with motion reduced, the figure is simply finished.
const GLIDE = "cubic-bezier(0.16, 1, 0.3, 1)"
const SPRING = "cubic-bezier(0.34, 1.56, 0.64, 1)"
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
const pick = (root, role) => Array.from(root.querySelectorAll(`[data-anim="${role}"]`))

// Shows an element (the stylesheet hides it until a scene runs) and plays it in from `from`.
const play = (els, from, { at = 0, each = 0, duration = 0.55, easing = GLIDE } = {}) => els.forEach((el, i) => {
  el.style.opacity = "1"
  el.animate([from, { opacity: 1, transform: "none" }], { duration: duration * 1000, delay: (at + i * each) * 1000, easing, fill: "backwards" })
})
const rise = (els, at, each = 0) => play(els, { opacity: 0, transform: "translateY(14px)" }, { at, each })
const pop = (els, at, each = 0) => play(els, { opacity: 0, transform: "scale(0.5)" }, { at, each, duration: 0.45, easing: SPRING })
const slideIn = (els, at, each = 0, from = -28) => play(els, { opacity: 0, transform: `translateX(${from}px)` }, { at, each, duration: 0.5 })
const countUp = (el, at, duration = 1.2) => {
  const to = Number(el.dataset.count)
  if (!Number.isFinite(to)) return
  el.style.opacity = "1"
  setTimeout(() => {
    const t0 = performance.now()
    const tick = (now) => {
      const p = Math.min(1, (now - t0) / (duration * 1000))
      el.textContent = String(Math.round(to * (1 - Math.pow(1 - p, 3))))
      if (p < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }, at * 1000)
}

const scenes = {
  "three-kinds": (root) => rise(pick(root, "col"), 0, 0.12),
  thermostat: (root) => {
    rise(pick(root, "panel"), 0, 0.14)
    pop(pick(root, "dial"), 0.3)
    rise(pick(root, "temp"), 0.34)
    rise(pick(root, "room"), 0.45)
    rise(pick(root, "sees"), 0.5, 0.08)
    rise(pick(root, "leak"), 0.75)
    root.querySelectorAll(".tvs-leak span").forEach((el, i) => {
      el.animate([{ opacity: 0, transform: "translateX(0)" }, { opacity: 0.9, offset: 0.5 }, { opacity: 0, transform: "translateX(190px)" }],
        { duration: 2200, delay: 1000 + i * 260, iterations: Infinity, easing: "linear" })
    })
    rise(pick(root, "cell"), 0.55, 0.07)
    const scan = pick(root, "scan")[0]
    if (scan) scan.animate([{ opacity: 0, transform: "translateX(-40%)" }, { opacity: 1, offset: 0.3 }, { opacity: 1, offset: 0.7 }, { opacity: 0, transform: "translateX(300%)" }],
      { duration: 1500, delay: 500, easing: GLIDE, fill: "both" })
    pop(pick(root, "flag"), 1.5)
    rise(pick(root, "verdict"), 1.7, 0.12)
  },
  surface: (root) => {
    const then = pick(root, "count-then")[0]
    const now = pick(root, "count-now")[0]
    if (then) countUp(then, 0.1, 0.7)
    if (now) countUp(now, 0.5, 1.6)
    const cells = (role, at, span) => {
      const els = pick(root, role)
      els.forEach((el, i) => play([el], { opacity: 0, transform: "scale(0.2)" }, { at: at + (i / Math.max(1, els.length)) * span, duration: 0.35 }))
    }
    cells("cell-then", 0.15, 0.5)
    cells("cell-now", 0.5, 1.5)
  },
  review: (root) => { slideIn(pick(root, "beat"), 0, 0.13); rise(pick(root, "split"), 0.85); rise(pick(root, "fix"), 1.05) },
  atomic: (root) => { rise(pick(root, "col"), 0, 0.14); slideIn(pick(root, "step"), 0.35, 0.12); slideIn(pick(root, "undo"), 0.85, 0.12, 28) },
  insights: (root) => { rise(pick(root, "col"), 0, 0.12); rise(pick(root, "metric"), 0.25, 0.07); pop(pick(root, "gap"), 0.85); rise(pick(root, "warn"), 1.15) }
}

// Anything a scene didn't claim is shown anyway: a missing flourish, never a missing graphic.
const sweep = (root) => root.querySelectorAll("[data-anim]").forEach((el) => { el.style.opacity = "1" })

const roots = Array.from(document.querySelectorAll("[data-fig-scene]"))
if (roots.length && !reduced && "IntersectionObserver" in window) {
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (!e.isIntersecting) continue
      io.unobserve(e.target)
      scenes[e.target.dataset.figScene]?.(e.target)
      sweep(e.target)
    }
  }, { rootMargin: "0px 0px -12% 0px", threshold: 0.18 })
  roots.forEach((r) => io.observe(r))
} else {
  roots.forEach(sweep)
}
