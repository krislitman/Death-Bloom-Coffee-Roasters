import { Controller } from "@hotwired/stimulus"

// Manages auth modals (sign-in and sign-up) with fade-in / fade-out animations.
// Usage:
//   data-controller="dialog" on an ancestor element (body works fine)
//   data-action="dialog#open" data-dialog-modal-param="sign-in"  (or "sign-up")
//   data-action="dialog#close" on close buttons inside each modal
//   data-action="dialog#closeOnOverlay" on each backdrop overlay
//   data-action="keydown.esc@window->dialog#closeOnEscape"
export default class extends Controller {
  static targets = ["modal", "overlay"]

  // ── Internals ──────────────────────────────────────────────────────────────

  #elementsFor(id) {
    const modal   = this.modalTargets.find(el => el.dataset.dialogId === id)
    const overlay = this.overlayTargets.find(el => el.dataset.dialogId === id)
    return { modal, overlay }
  }

  #focusableElements(container) {
    return Array.from(
      container.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    )
  }

  #trapFocus(modal) {
    const focusable = this.#focusableElements(modal)
    if (!focusable.length) return

    const first = focusable[0]
    const last  = focusable[focusable.length - 1]

    this._trapHandler = (event) => {
      if (event.key !== "Tab") return
      if (event.shiftKey) {
        if (document.activeElement === first) {
          event.preventDefault()
          last.focus()
        }
      } else {
        if (document.activeElement === last) {
          event.preventDefault()
          first.focus()
        }
      }
    }

    modal.addEventListener("keydown", this._trapHandler)
    first.focus()
  }

  #releaseFocus(modal) {
    if (this._trapHandler) {
      modal.removeEventListener("keydown", this._trapHandler)
      this._trapHandler = null
    }
  }

  // Show modal + overlay with fade-in animation
  #showElements(modal, overlay) {
    overlay.classList.remove("hidden", "animate-fade-out")
    modal.classList.remove("hidden", "animate-fade-out")
    // Force reflow so the animation starts fresh even if just removed
    void modal.offsetWidth
    overlay.classList.add("animate-fade-in")
    modal.classList.add("animate-fade-in")
    document.body.style.overflow = "hidden"
  }

  // Hide modal + overlay, optionally with fade-out animation
  #hideElements(modal, overlay, animated = true) {
    this.#releaseFocus(modal)

    if (animated) {
      modal.classList.remove("animate-fade-in")
      overlay.classList.remove("animate-fade-in")
      modal.classList.add("animate-fade-out")
      overlay.classList.add("animate-fade-out")

      // After animation completes, apply display:none via .hidden
      setTimeout(() => {
        modal.classList.add("hidden")
        modal.classList.remove("animate-fade-out")
        overlay.classList.add("hidden")
        overlay.classList.remove("animate-fade-out")
      }, 300)
    } else {
      modal.classList.add("hidden")
      modal.classList.remove("animate-fade-in", "animate-fade-out")
      overlay.classList.add("hidden")
      overlay.classList.remove("animate-fade-in", "animate-fade-out")
    }

    document.body.style.overflow = ""
    this._activeModalId = null
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  // data-action="dialog#open" data-dialog-modal-param="sign-in"
  open(event) {
    event.preventDefault()
    const id = event.params.modal
    const { modal, overlay } = this.#elementsFor(id)
    if (!modal || !overlay) return

    // Instantly close any currently open modal before opening the new one
    if (this._activeModalId && this._activeModalId !== id) {
      const { modal: prev, overlay: prevOv } = this.#elementsFor(this._activeModalId)
      if (prev && prevOv) this.#hideElements(prev, prevOv, false)
    }

    this._activeModalId = id
    this.#showElements(modal, overlay)
    this.#trapFocus(modal)
  }

  close() {
    if (!this._activeModalId) return
    const { modal, overlay } = this.#elementsFor(this._activeModalId)
    if (modal && overlay) this.#hideElements(modal, overlay, true)
  }

  // data-action="dialog#closeOnOverlay" on the backdrop div
  closeOnOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }

  // data-action="keydown.esc@window->dialog#closeOnEscape"
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Switch from sign-in → sign-up (or vice versa): instantly hide current, fade in next
  // data-action="dialog#switchTo" data-dialog-modal-param="sign-up"
  switchTo(event) {
    event.preventDefault()
    const id = event.params.modal

    if (this._activeModalId) {
      const { modal: prev, overlay: prevOv } = this.#elementsFor(this._activeModalId)
      if (prev && prevOv) this.#hideElements(prev, prevOv, false)
    }

    const { modal, overlay } = this.#elementsFor(id)
    if (!modal || !overlay) return

    this._activeModalId = id
    this.#showElements(modal, overlay)
    this.#trapFocus(modal)
  }
}
