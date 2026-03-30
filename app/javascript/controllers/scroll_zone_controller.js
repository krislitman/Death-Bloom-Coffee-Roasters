// scroll_zone_controller.js
//
// Observes section elements and swaps zone classes (zone--dark / zone--light)
// as they enter the viewport.  Works via IntersectionObserver so there is zero
// scroll event listener overhead.
//
// Usage on a section:
//   <section data-controller="scroll-zone" data-scroll-zone-theme-value="light">
//
// Usage on the nav to react to scroll depth:
//   <nav data-controller="scroll-zone" data-scroll-zone-nav-value="true">

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    theme: { type: String, default: "dark" },  // "dark" | "light"
    nav:   { type: Boolean, default: false },   // true on the <nav> to track scroll
  }

  connect() {
    if (this.navValue) {
      this.#observeScroll()
    } else {
      this.#observeIntersection()
    }
  }

  disconnect() {
    this.#observer?.disconnect()
    this.#scrollHandler && window.removeEventListener("scroll", this.#scrollHandler, { passive: true })
  }

  // ── Private ────────────────────────────────────────────────────────────────

  #observer = null
  #scrollHandler = null

  #observeIntersection() {
    this.#observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          this.#applyTheme(entry.target)
        })
      },
      { threshold: 0.3 }
    )
    this.#observer.observe(this.element)
  }

  #applyTheme(el) {
    const isDark = this.themeValue === "dark"
    el.classList.toggle("zone--dark",  isDark)
    el.classList.toggle("zone--light", !isDark)
  }

  #observeScroll() {
    this.#scrollHandler = () => {
      const scrolled = window.scrollY > 30
      this.element.classList.toggle("nav--scrolled", scrolled)
    }
    window.addEventListener("scroll", this.#scrollHandler, { passive: true })
    // Apply immediately on connect in case page is pre-scrolled
    this.#scrollHandler()
  }
}
