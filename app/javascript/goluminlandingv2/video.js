// The hero's promo (HeroVideo.astro): nothing fetched until it's near the
// screen, muted autoplay, paused off-screen, sound one tap away, and a play
// button instead of motion for reduced-motion visitors.
for (const root of document.querySelectorAll("[data-hero-video]")) {
  const video = root.querySelector("video")
  const play = root.querySelector("[data-play]")
  const sound = root.querySelector("[data-sound]")
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
  let loaded = false
  let wanted = !reduced

  const load = () => {
    if (loaded) return
    loaded = true
    video.querySelectorAll("source").forEach((s) => { s.src = s.dataset.src })
    video.load()
  }
  const showPlay = (on) => { play.classList.toggle("hidden", !on); play.classList.toggle("flex", on) }
  const start = () => { load(); video.play().then(() => showPlay(false), () => showPlay(true)) }

  showPlay(reduced)
  play.addEventListener("click", () => { wanted = true; start() })
  video.addEventListener("click", () => {
    if (video.paused) { wanted = true; start() } else { wanted = false; video.pause(); showPlay(true) }
  })
  sound.addEventListener("click", () => {
    video.muted = !video.muted
    if (!video.muted) { video.currentTime = 0; wanted = true; start() }
    sound.setAttribute("aria-pressed", String(!video.muted))
    sound.querySelector("[data-label]").textContent = video.muted ? "Sound on" : "Sound off"
    sound.querySelector("[data-on]").classList.toggle("hidden", video.muted)
    sound.querySelector("[data-off]").classList.toggle("hidden", !video.muted)
  })
  new IntersectionObserver(([e]) => {
    if (e.isIntersecting) { if (wanted) start(); else load() } else if (!video.paused) video.pause()
  }, { rootMargin: "200px 0px", threshold: 0.25 }).observe(root)
}
