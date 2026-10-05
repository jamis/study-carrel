import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken } from "lib/request"

const FIRST_RETRY = 5000
const MAX_RETRY = 60000
// Browsers refuse keepalive requests with bodies over 64 KB.
const KEEPALIVE_LIMIT = 60000

// The always-open note editor: saves a moment after typing stops, when focus leaves the
// editor, and when the verse changes (this controller disconnecting).
//
// While the editor is on screen, failed saves retry with backoff. Once it's gone it never
// retries: a newer editor for the same verse may have saved since. Instead, text that didn't
// save waits in sessionStorage and comes back the next time this verse's editor opens.
export default class extends Controller {
  static targets = ["editor", "status"]
  static values = { unitId: Number, focusId: Number, delay: { type: Number, default: 800 } }

  connect() {
    this.attempts = 0
    this.retryNow = () => { if (this.retrying && document.visibilityState === "visible") this.save() }
    window.addEventListener("online", this.retryNow)
    document.addEventListener("visibilitychange", this.retryNow)
  }

  disconnect() {
    window.removeEventListener("online", this.retryNow)
    document.removeEventListener("visibilitychange", this.retryNow)
    this.disconnected = true
    this.save()
  }

  // Lexxy may normalize the stored HTML on load; remember that as "already saved".
  ready() {
    this.saved = this.editorTarget.value

    const unsaved = this.#unsaved
    if (unsaved == null) return
    this.editorTarget.value = unsaved
    if (this.editorTarget.value === this.saved) {
      this.#unsaved = null
    } else {
      this.restored = true
      this.save()
    }
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
    this.retrying = false
    if (this.inflight) { this.queued = true; return }

    const value = this.editorTarget.value
    if (value === this.saved) return

    this.inflight = true
    this.#status("Saving…")
    let failure = "Couldn't save; retrying…"
    let retry = true
    try {
      const body = JSON.stringify({ focus_id: this.focusIdValue, note: { content: value } })
      const response = await fetch(this.element.action, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken()
        },
        body,
        keepalive: body.length < KEEPALIVE_LIMIT
      })
      // fetch follows redirects, so a save bounced to the sign-in page still looks ok; it saved nothing.
      // The session cookie is shared, so signing in from another tab lets the next retry through.
      if (response.redirected) {
        failure = "Not saved: you've been signed out. Sign in from another tab and it will save."
        throw new Error("redirected")
      }
      if (!response.ok) {
        // Server trouble may pass; any other refusal will only repeat.
        retry = response.status >= 500 || response.status === 408 || response.status === 429
        if (response.status === 409) failure = "Not saved: this focus is no longer current."
        else if (!retry) failure = "Couldn't save this note."
        throw new Error(response.status)
      }

      this.saved = value
      this.attempts = 0
      this.#unsaved = null
      const noted = response.headers.get("X-Noted") === "true"
      window.dispatchEvent(new CustomEvent("note:saved", { detail: { unitId: this.unitIdValue, noted } }))
      Turbo.renderStreamMessage(await response.text())
      this.#status(this.restored ? "Saved changes that hadn't saved before" : "Saved")
      this.restored = false
    } catch {
      this.#unsaved = value
      this.#status(failure)
      if (retry && !this.disconnected) {
        this.retrying = true
        this.timer = setTimeout(() => this.save(), Math.min(FIRST_RETRY * 2 ** this.attempts++, MAX_RETRY))
      }
    } finally {
      this.inflight = false
      if (this.queued) { this.queued = false; this.save() }
    }
  }

  get #storageKey() {
    return `unsaved-note:${this.focusIdValue}:${this.unitIdValue}`
  }

  // Storage can be unavailable (private windows, blocked site data); then there's nothing to restore.
  get #unsaved() {
    try { return sessionStorage.getItem(this.#storageKey) } catch { return null }
  }

  set #unsaved(value) {
    try {
      if (value == null) sessionStorage.removeItem(this.#storageKey)
      else sessionStorage.setItem(this.#storageKey, value)
    } catch {}
  }

  #status(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
