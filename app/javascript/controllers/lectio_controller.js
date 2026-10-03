import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Switches verses client-side; the whole section is already on the page.
export default class extends Controller {
  static targets = ["unit", "prev", "now", "body", "next", "ref", "tick", "count", "strip", "editor"]
  static values = { current: Number, base: String, refTemplate: String, positionUrl: String, unitName: String,
    noteUrlTemplate: String, prevUrl: String, prevLabel: String, nextUrl: String, nextLabel: String }

  connect() {
    this.bodies = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.textContent.trim()]))
    this.numbers = [...this.bodies.keys()].sort((a, b) => a - b)

    this.unitIds = new Map(this.unitTargets.map(u => [Number(u.dataset.number), Number(u.dataset.unitId)]))
    // Which verses have a note; the editor reports changes as it autosaves.
    this.noted = new Set(this.tickTargets.filter(t => t.classList.contains("has")).map(t => Number(t.dataset.number)))
    this.updateCount()
    this.scrollStripToCurrent()
    this.savePosition()
  }

  disconnect() {
    clearTimeout(this.saveTimer)
  }

  next() { this.step(1) }
  previous() { this.step(-1) }
  go(event) { this.select(Number(event.currentTarget.dataset.number)) }

  // Past either end of the chapter, carry on into the neighboring one.
  step(delta) {
    const i = this.numbers.indexOf(this.currentValue) + delta
    if (i >= 0 && i < this.numbers.length) return this.select(this.numbers[i])

    const url = delta > 0 ? this.nextUrlValue : this.prevUrlValue
    if (url) Turbo.visit(url)
  }

  select(number) {
    if (!this.bodies.has(number)) return
    this.currentValue = number
    history.replaceState(history.state, "", `${this.baseValue}/${number}`)
    this.render()
    this.savePosition()
  }

  // Tell the server where we are (debounced), so the app reopens here.
  savePosition() {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      const unitId = this.unitIds.get(this.currentValue)
      if (!unitId) return
      fetch(this.positionUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
        body: JSON.stringify({ unit_id: unitId }),
        keepalive: true
      })
    }, 400)
  }

  render() {
    const n = this.currentValue
    const i = this.numbers.indexOf(n)
    this.fillNear(this.prevTarget, this.numbers[i - 1], "←", this.prevLabelValue)
    this.fillNear(this.nextTarget, this.numbers[i + 1], "→", this.nextLabelValue)

    const body = this.bodies.get(n)
    this.nowTarget.className = "now" + (body.length > 450 ? " long" : body.length > 180 ? " mid" : "")
    this.bodyTarget.textContent = body
    this.refTargets.forEach(r => r.textContent = this.refTemplateValue.replace("{n}", n))
    this.tickTargets.forEach(t => {
      const current = Number(t.dataset.number) === n
      t.classList.toggle("current", current)
      t.setAttribute("aria-current", current)
      t.tabIndex = current ? 0 : -1 // the strip is one tab stop; arrow keys move within it
      if (current && this.tickTargets.includes(document.activeElement)) t.focus({ preventScroll: true })
    })
    this.scrollStripToCurrent()

    // Swapping the frame replaces the editor; the old one saves itself as it goes.
    this.editorTarget.src = this.noteUrlTemplateValue.replace("%7Bid%7D", this.unitIds.get(n)).replace("{id}", this.unitIds.get(n))
    this.updateCount()
  }

  // A long chapter's strip is a single scrolling row; keep the current number in view.
  scrollStripToCurrent() {
    if (!this.hasStripTarget || !this.stripTarget.classList.contains("scrolling")) return
    const tick = this.tickTargets.find(t => Number(t.dataset.number) === this.currentValue)
    const strip = this.stripTarget
    if (tick) strip.scrollLeft = tick.offsetLeft - (strip.clientWidth - tick.offsetWidth) / 2
  }

  noteSaved({ detail: { unitId, noted } }) {
    const number = [...this.unitIds].find(([, id]) => id === unitId)?.[0]
    if (number === undefined) return
    if (noted) this.noted.add(number); else this.noted.delete(number)
    this.updateCount()
  }

  updateCount() {
    this.countTarget.textContent = this.noted.has(this.currentValue) ? "Has a note" : "No note yet"
    this.updateMarkers()
  }

  // The strip marks every verse that has a note.
  updateMarkers() {
    this.tickTargets.forEach(tick => {
      const n = Number(tick.dataset.number)
      const has = this.noted.has(n)
      tick.classList.toggle("has", has)
      tick.setAttribute("aria-label", has ? `${this.unitNameValue} ${n}, has a note` : `${this.unitNameValue} ${n}`)
    })
  }

  // The faded neighbor above or below; at a chapter's edge it names the adjacent chapter instead.
  fillNear(el, number, arrow, edgeLabel) {
    el.replaceChildren()
    el.classList.remove("edge")
    const b = document.createElement("b")
    if (number !== undefined) {
      b.textContent = number
      el.append(b, this.bodies.get(number))
    } else if (edgeLabel) {
      b.textContent = arrow
      el.classList.add("edge")
      el.append(b, edgeLabel)
    }
  }

  touchStart(event) {
    // Dragging the verse strip scrolls it; it must not also turn the page.
    if (this.hasStripTarget && this.stripTarget.contains(event.target)) { this.touchStartPoint = undefined; return }
    const { clientX, clientY } = event.touches[0]
    this.touchStartPoint = { x: clientX, y: clientY }
  }

  // Only a mostly-horizontal swipe turns the page; scrolling a long passage drifts sideways too.
  touchEnd(event) {
    if (!this.touchStartPoint) return
    const { clientX, clientY } = event.changedTouches[0]
    const dx = clientX - this.touchStartPoint.x
    const dy = clientY - this.touchStartPoint.y
    this.touchStartPoint = undefined
    if (Math.abs(dx) > 60 && Math.abs(dx) > 2 * Math.abs(dy)) this.step(dx < 0 ? 1 : -1)
  }

  key(event) {
    if (event.target.closest("input, textarea, [contenteditable]") || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "ArrowRight" || event.key === "j") this.next()
    if (event.key === "ArrowLeft" || event.key === "k") this.previous()
  }
}
