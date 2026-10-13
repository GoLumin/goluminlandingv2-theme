// The hero's proof line (HeroMetrics.astro): each figure punched in and
// counted up, one at a time, while it's on screen.
const root = document.querySelector("[data-hero-metrics]")
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
if (root && !reduced) {
  const slides = [...root.querySelectorAll(".metric")]
  const segs = [...root.querySelectorAll("[data-seg]")]
  const HOLD = 2600, IN = 520, OUT = 340, COUNT = 950
  const outExpo = (x) => (x >= 1 ? 1 : 1 - Math.pow(2, -10 * x))
  const format = (el, v) => {
    const d = Number(el.dataset.decimals)
    return `${el.dataset.prefix}${v.toLocaleString("en-US", { minimumFractionDigits: d, maximumFractionDigits: d })}${el.dataset.suffix}`
  }
  const countUp = (el) => {
    const n = el.querySelector("[data-n]")
    const target = Number(el.dataset.value)
    const t0 = performance.now()
    const tick = (now) => {
      const p = Math.min(1, (now - t0) / COUNT)
      n.textContent = format(el, target * outExpo(p))
      if (p < 1) requestAnimationFrame(tick)
      else n.animate([{ transform: "scale(1.09)" }, { transform: "scale(1)" }], { duration: 380, easing: "cubic-bezier(.3,1.6,.5,1)" })
    }
    requestAnimationFrame(tick)
  }
  const punchIn = (el) => {
    el.style.opacity = "1"
    el.animate([
      { opacity: 0, transform: "translateY(70%) scale(.86)", filter: "blur(8px)" },
      { opacity: 1, transform: "translateY(0) scale(1)", filter: "blur(0)" }
    ], { duration: IN, easing: "cubic-bezier(.2,1.35,.4,1)" })
    countUp(el)
  }
  const punchOut = (el) => el.animate([
    { opacity: 1, transform: "translateY(0) scale(1)", filter: "blur(0)" },
    { opacity: 0, transform: "translateY(-70%) scale(1.06)", filter: "blur(8px)" }
  ], { duration: OUT, easing: "cubic-bezier(.6,0,.9,.4)", fill: "forwards" }).finished.then((a) => { a.cancel(); el.style.opacity = "0" })

  let i = 0, timer = 0, running = false, visible = false
  const fill = (k) => {
    segs.forEach((s, j) => { s.getAnimations().forEach((a) => a.cancel()); s.style.width = j < k ? "100%" : "0" })
    segs[k]?.animate([{ width: "0" }, { width: "100%" }], { duration: IN + HOLD, easing: "linear", fill: "forwards" })
  }
  const show = (k) => { punchIn(slides[k]); fill(k) }
  const step = () => {
    const prev = slides[i]
    i = (i + 1) % slides.length
    if (i === 0) segs.forEach((s) => { s.getAnimations().forEach((a) => a.cancel()); s.style.width = "0" })
    punchOut(prev).then(() => { if (running) { show(i); timer = window.setTimeout(step, IN + HOLD) } })
  }
  const start = () => {
    if (running || !visible || document.hidden) return
    running = true
    if (!timer) show(i)
    timer = window.setTimeout(step, IN + HOLD)
  }
  const stop = () => { running = false; clearTimeout(timer); timer = -1 }

  slides.slice(1).forEach((s) => { s.style.opacity = "0" })
  if (slides.length > 1) {
    new IntersectionObserver(([e]) => { visible = e.isIntersecting; visible ? start() : stop() }, { threshold: 0.5 }).observe(root)
    document.addEventListener("visibilitychange", () => (document.hidden ? stop() : start()))
  } else if (slides.length) {
    new IntersectionObserver(([e], io) => { if (e.isIntersecting) { visible = true; show(0); io.disconnect() } }, { threshold: 0.5 }).observe(root)
  }
}
