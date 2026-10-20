import { Controller } from "@hotwired/stimulus"
import { citeOf, labelIdsOf, escapeHtml } from "lib/notes"

// A note's labels as footnotes, on the reread page (alongside the reread and compare controllers). Pointing at a mark
// (data-fn-label) shows its label: its face and its other notes on this focus. Pointing at a reference (data-fn-note),
// in a footnote line or on the comparison's card, shows that note: its passage and what's written. A tap does the same
// on a touch screen. From the pop-up, "Go to it" makes the note the one you're on; while comparing, "Hold it" holds it
// under a tab. Clicking a reference with a mouse, which has shown it already, does that straight away.
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

  get #comparing() { return this.element.classList.contains("comparing") }
  #rowOf(noteId) { return noteId ? this.element.querySelector(`.rr-row[data-note-id="${noteId}"]`) : null }

  // ---------- showing ----------

  // A mouse, not a finger: pointing shows, and a click acts. (A tap shows, and a second tap puts it away.)
  #byMouse(event) { return event.pointerType ? event.pointerType === "mouse" : this.canHover }

  #point(event) {
    if (!this.#byMouse(event)) return
    const trigger = event.target.closest?.("[data-fn-label], [data-fn-note]")
    if (trigger) return this.#show(trigger)
    if (this.popTarget.contains(event.target)) return clearTimeout(this.timer)
    if (this.shownFor) { clearTimeout(this.timer); this.timer = setTimeout(() => this.hide(), 180) }
  }

  #click(event) {
    const go = event.target.closest("[data-fn-go]")
    if (go) { event.stopPropagation(); this.hide(); return this.#go(go.dataset.fnGo) }
    const trigger = event.target.closest("[data-fn-label], [data-fn-note]")
    if (!trigger) { if (!this.popTarget.contains(event.target)) this.hide(); return }
    if (trigger.hasAttribute("data-fn-peek")) return this.hide()
    event.stopPropagation()
    const byMouse = this.#byMouse(event)
    if (byMouse && trigger.dataset.fnNote) { this.hide(); return this.#go(trigger.dataset.fnNote) }
    trigger === this.shownFor && !byMouse ? this.hide() : this.#show(trigger)
  }

  #show(trigger) {
    clearTimeout(this.timer)
    if (trigger === this.shownFor) return
    this.shownFor?.classList.remove("open")
    this.shownFor = trigger
    trigger.classList.add("open")
    const pop = this.popTarget
    const from = trigger.dataset.fnFrom || trigger.closest(".rr-row")?.dataset.noteId
    if (trigger.dataset.fnLabel) this.#showLabel(trigger.dataset.fnLabel, from)
    else this.#showNote(trigger.dataset.fnNote, trigger)
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

  // A label: its face, as seen from the note it was pointed at on, and its other notes.
  #showLabel(labelId, from) {
    const label = this.#labels.get(labelId)
    const face = label ? (String(label.example) === from ? label.alt : label.face) : ""
    const rows = [...this.element.querySelectorAll(".rr-row[data-note-id]")]
      .filter(row => row.dataset.noteId && row.dataset.noteId !== from && labelIdsOf(row).includes(labelId))
    this.popTarget.classList.remove("fn-one")
    this.popTarget.innerHTML = `<div class="fn-face">${face}</div>` +
      (rows.map(row => this.#noteHtml(row)).join("") || `<p class="fn-none">Only this note, on this focus.</p>`)
  }

  #showNote(noteId, trigger) {
    const row = this.#rowOf(noteId)
    this.popTarget.classList.add("fn-one")
    this.popTarget.innerHTML = row ? this.#noteHtml(row)
      : `<p class="fn-none">${escapeHtml(trigger.textContent.trim())} isn't among the notes shown here.</p>`
  }

  #noteHtml(row) {
    const passage = row.querySelector(".rr-passage")?.textContent.trim()
    const note = row.querySelector(".rr-note")?.innerHTML || ""
    const here = row.classList.contains("here")
    const go = here && !this.#comparing ? "" : `<button type="button" class="fn-go" data-fn-go="${row.dataset.noteId}">${this.#comparing ? "Hold it" : "Go to it"}</button>`
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

  get #labels() {
    const json = this.element.querySelector("#reread_labels script[type='application/json']")
    try { return new Map(JSON.parse(json.textContent).map(label => [ String(label.id), label ])) } catch { return new Map() }
  }

  // ---------- going ----------

  #go(noteId) {
    const row = this.#rowOf(noteId)
    if (!row) return
    if (this.#comparing) this.application.getControllerForElementAndIdentifier(this.element, "compare")?.hold(row)
    else this.application.getControllerForElementAndIdentifier(this.element, "reread")?.goTo(row)
  }

  // Esc puts the pop-up away before anything else hears it.
  key(event) {
    if (event.key !== "Escape" || this.popTarget.hidden) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.hide()
  }
}
