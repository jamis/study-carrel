import { Controller } from "@hotwired/stimulus"
import { citeOf, escapeHtml } from "lib/notes"

// A note shown from its reference, on the reread page while gathering (alongside the reread and compare controllers).
// Pointing at a reference on the Gather card (data-fn-note) shows that note: its passage and what's written. A tap does
// the same on a touch screen. From the pop-up, "Hold it" holds the note under a tab. Clicking a reference with a mouse,
// which has shown it already, does that straight away.
// data-fn-peek: shows the note when pointed at, but a click is left to what it's on (the card's tabs).
export default class extends Controller {
  static targets = ["pop"]

  connect() {
    this.canHover = matchMedia("(hover: hover)").matches
    this.element.addEventListener("pointerover", this.pointed = event => this.#point(event))
    this.element.addEventListener("click", this.clicked = event => this.#click(event), true)
    addEventListener("scroll", this.scrolled = () => this.hide(), { passive: true })
  }

  disconnect() {
    clearTimeout(this.timer)
    this.element.removeEventListener("pointerover", this.pointed)
    this.element.removeEventListener("click", this.clicked, true)
    removeEventListener("scroll", this.scrolled)
  }

  #rowOf(noteId) { return noteId ? this.element.querySelector(`.rr-row[data-note-id="${noteId}"]`) : null }

  // ---------- showing ----------

  // A mouse, not a finger: pointing shows, and a click acts. (A tap shows, and a second tap puts it away.)
  #byMouse(event) { return event.pointerType ? event.pointerType === "mouse" : this.canHover }

  #point(event) {
    if (!this.#byMouse(event)) return
    const trigger = event.target.closest?.("[data-fn-note]")
    if (trigger) return this.#show(trigger)
    if (this.popTarget.contains(event.target)) return clearTimeout(this.timer)
    if (this.shownFor) { clearTimeout(this.timer); this.timer = setTimeout(() => this.hide(), 180) }
  }

  #click(event) {
    const go = event.target.closest("[data-fn-go]")
    if (go) { event.stopPropagation(); this.hide(); return this.#go(go.dataset.fnGo) }
    const trigger = event.target.closest("[data-fn-note]")
    if (!trigger) { if (!this.popTarget.contains(event.target)) this.hide(); return }
    if (trigger.hasAttribute("data-fn-peek")) return this.hide()
    event.stopPropagation()
    const byMouse = this.#byMouse(event)
    if (byMouse) { this.hide(); return this.#go(trigger.dataset.fnNote) }
    trigger === this.shownFor && !byMouse ? this.hide() : this.#show(trigger)
  }

  #show(trigger) {
    clearTimeout(this.timer)
    if (trigger === this.shownFor) return
    this.shownFor?.classList.remove("open")
    this.shownFor = trigger
    trigger.classList.add("open")
    const pop = this.popTarget
    this.#showNote(trigger.dataset.fnNote, trigger)
    pop.style.setProperty("--c", getComputedStyle(trigger).getPropertyValue("--c").trim() || "var(--accent)")
    pop.hidden = false
    this.#place(trigger)
  }

  hide() {
    clearTimeout(this.timer)
    this.shownFor?.classList.remove("open")
    this.shownFor = null
    this.popTarget.hidden = true
  }

  #showNote(noteId, trigger) {
    const row = this.#rowOf(noteId)
    this.popTarget.innerHTML = row ? this.#noteHtml(row)
      : `<p class="fn-none">${escapeHtml(trigger.textContent.trim())} isn't among the notes shown here.</p>`
  }

  #noteHtml(row) {
    const passage = row.querySelector(".rr-passage")?.textContent.trim()
    const note = row.querySelector(".rr-note")?.innerHTML || ""
    const go = `<button type="button" class="fn-go" data-fn-go="${row.dataset.noteId}">Hold it</button>`
    return `<div class="fn-note">
      <div class="fn-ref"><span class="rr-ref${row.classList.contains("rr-free") ? " rr-whole" : ""}">${escapeHtml(citeOf(row))}</span>${go}</div>
      ${passage ? `<p class="rr-passage">${escapeHtml(passage)}</p>` : ""}
      <div class="rr-note">${note}</div>
    </div>`
  }

  // Under what it's for, or over it when there's more room there; kept on screen.
  #place(trigger) {
    const pop = this.popTarget, r = trigger.getBoundingClientRect()
    const width = pop.offsetWidth, height = pop.offsetHeight
    const left = Math.max(12, Math.min(innerWidth - width - 12, r.left - 14))
    const below = r.bottom + 8 + height <= innerHeight || r.top < innerHeight - r.bottom
    pop.style.left = `${left}px`
    pop.style.top = `${below ? r.bottom + 8 : Math.max(8, r.top - 8 - height)}px`
  }

  // ---------- going ----------

  #go(noteId) {
    const row = this.#rowOf(noteId)
    if (row) this.application.getControllerForElementAndIdentifier(this.element, "compare")?.hold(row)
  }

  // Esc puts the pop-up away before anything else hears it.
  key(event) {
    if (event.key !== "Escape" || this.popTarget.hidden) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.hide()
  }
}
