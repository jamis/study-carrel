import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken } from "lib/request"

// The always-open note editor: saves a moment after typing stops, when focus leaves the
// editor, and when the verse changes (this controller disconnecting). Failed saves retry.
export default class extends Controller {
  static targets = ["editor", "status"]
  static values = { unitId: Number, delay: { type: Number, default: 800 } }

  disconnect() {
    clearTimeout(this.timer)
    this.save()
  }

  // Lexxy may normalize the stored HTML on load; remember that as "already saved".
  ready() {
    this.saved = this.editorTarget.value
  }

  changed() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.save(), this.delayValue)
  }

  // The form is never submitted by hand; Enter must not leave the page.
  prevent(event) {
    event.preventDefault()
  }

  async save() {
    clearTimeout(this.timer)
    if (this.inflight) { this.queued = true; return }

    const value = this.editorTarget.value
    if (value === this.saved) return

    this.inflight = true
    this.#status("Saving…")
    let failure = "Couldn't save; retrying…"
    try {
      const response = await fetch(this.element.action, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken()
        },
        body: JSON.stringify({ note: { content: value } }),
        keepalive: true
      })
      // fetch follows redirects, so a save bounced to the sign-in page still looks ok; it saved nothing.
      // The session cookie is shared, so signing in from another tab lets the next retry through.
      if (response.redirected) {
        failure = "Not saved: you've been signed out. Sign in from another tab and it will save."
        throw new Error("redirected")
      }
      if (!response.ok) throw new Error(response.status)

      this.saved = value
      const noted = response.headers.get("X-Noted") === "true"
      window.dispatchEvent(new CustomEvent("note:saved", { detail: { unitId: this.unitIdValue, noted } }))
      Turbo.renderStreamMessage(await response.text())
      this.#status("Saved")
    } catch {
      this.#status(failure)
      this.timer = setTimeout(() => this.save(), 5000)
    } finally {
      this.inflight = false
      if (this.queued) { this.queued = false; this.save() }
    }
  }

  #status(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
