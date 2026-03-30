// announcement_bar_controller.js
//
// Dismissible top bar with localStorage persistence.
// The bar is shown only when the `announcement_bar` Flipper flag is enabled
// (the server renders the element conditionally).  Once dismissed, it stays
// hidden until the `storageKey` changes (i.e. a new announcement).
//
// Usage:
//   <div data-controller="announcement-bar"
//        data-announcement-bar-storage-key-value="announcement-2026-spring">
//     <p>Free shipping on orders over $50</p>
//     <button data-action="announcement-bar#dismiss">×</button>
//   </div>

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "announcement-bar-dismissed" },
  }

  connect() {
    if (this.#isDismissed()) {
      this.element.hidden = true
    }
  }

  dismiss() {
    localStorage.setItem(this.storageKeyValue, "1")
    this.element.hidden = true
  }

  // ── Private ────────────────────────────────────────────────────────────────

  #isDismissed() {
    return localStorage.getItem(this.storageKeyValue) === "1"
  }
}
