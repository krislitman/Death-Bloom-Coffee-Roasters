import { Controller } from "@hotwired/stimulus"

// Manages auth modals (sign-in and sign-up).
// Usage:
//   data-controller="dialog" on a ancestor element (body works fine)
//   data-action="dialog#open" data-dialog-modal-param="sign-in"  (or "sign-up")
//   data-action="dialog#close" on close buttons inside each modal
//   data-action="dialog#closeOnOverlay" on each backdrop overlay
//   data-action="keydown.esc@window->dialog#closeOnEscape"
export default class extends Controller {
  static targets = ["modal", "overlay"]

  // ── Internals ──────────────────────────────────────────────────────────────

  // Returns the modal and overlay elements for a given id ("sign-in" / "sign-up")
  #elementsFor(id) {
    const modal   = this.modalTargets.find(el => el.dataset.dialogId === id)
    const overlay = this.overlayTargets.find(el => el.dataset.dialogId === id)
    return { modal, overlay }
  }

  // Collect all focusable children of an element
  #focusableElements(container) {
    return Array.from(
      container.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    )
  }

  // Trap Tab / Shift+Tab inside the modal
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

  // ── Public actions ─────────────────────────────────────────────────────────

  // data-action="dialog#open" data-dialog-modal-param="sign-in"
  open(event) {
    event.preventDefault()
    const id = event.params.modal
    const { modal, overlay } = this.#elementsFor(id)
    if (!modal || !overlay) return

    // Close any currently open modal first
    this.#closeAll()

    overlay.classList.remove("hidden")
    modal.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this._activeModalId = id

    this.#trapFocus(modal)
  }

  close() {
    this.#closeAll()
  }

  // data-action="dialog#closeOnOverlay" on the backdrop div
  closeOnOverlay(event) {
    if (event.target === event.currentTarget) {
      this.#closeAll()
    }
  }

  // data-action="keydown.esc@window->dialog#closeOnEscape"
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.#closeAll()
    }
  }

  // Switch from sign-in modal to sign-up (or vice-versa) without a page load
  // data-action="dialog#switchTo" data-dialog-modal-param="sign-up"
  switchTo(event) {
    event.preventDefault()
    const id = event.params.modal
    this.#closeAll()

    const { modal, overlay } = this.#elementsFor(id)
    if (!modal || !overlay) return

    overlay.classList.remove("hidden")
    modal.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this._activeModalId = id

    this.#trapFocus(modal)
  }

  // ── Private ────────────────────────────────────────────────────────────────

  #closeAll() {
    this.modalTargets.forEach(modal => {
      this.#releaseFocus(modal)
      modal.classList.add("hidden")
    })
    this.overlayTargets.forEach(overlay => overlay.classList.add("hidden"))
    document.body.style.overflow = ""
    this._activeModalId = null
  }
}
