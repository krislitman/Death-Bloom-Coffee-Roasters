import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "overlay"]

  open(event) {
    event.preventDefault()
    this.drawerTarget.classList.add("cart-drawer--open")
    this.overlayTarget.classList.add("cart-drawer__overlay--visible")
    document.body.classList.add("cart-drawer-active")
  }

  close() {
    this.drawerTarget.classList.remove("cart-drawer--open")
    this.overlayTarget.classList.remove("cart-drawer__overlay--visible")
    document.body.classList.remove("cart-drawer-active")
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  updateQuantity(event) {
    const form = event.target.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
