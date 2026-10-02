import { Controller } from "@hotwired/stimulus"

// Switches verses client-side; the whole section is already on the page.
export default class extends Controller {
  static targets = ["unit", "prev", "now", "body", "next", "ref", "tick", "notes", "count", "unitField"]
  static values = { current: Number, base: String, refPrefix: String }

  connect() {
    this.bodies = new Map(this.unitTargets.map(u => [Number(u.dataset.number), u.textContent.trim()]))
    this.numbers = [...this.bodies.keys()].sort((a, b) => a - b)

    // Notes are added and removed by Turbo streams; keep the count in step.
    this.observer = new MutationObserver(() => this.updateCount())
    this.notesTargets.forEach(el => this.observer.observe(el, { childList: true }))
    this.updateCount()
  }

  disconnect() { this.observer?.disconnect() }

  next() { this.step(1) }
  previous() { this.step(-1) }
  go(event) { this.select(Number(event.currentTarget.dataset.number)) }

  step(delta) {
    const i = this.numbers.indexOf(this.currentValue) + delta
    if (i >= 0 && i < this.numbers.length) this.select(this.numbers[i])
  }

  select(number) {
    if (!this.bodies.has(number)) return
    this.currentValue = number
    history.replaceState(null, "", `${this.baseValue}/${number}`)
    this.render()
  }

  render() {
    const n = this.currentValue
    const i = this.numbers.indexOf(n)
    this.fillNear(this.prevTarget, this.numbers[i - 1])
    this.fillNear(this.nextTarget, this.numbers[i + 1])

    const body = this.bodies.get(n)
    this.nowTarget.className = "now" + (body.length > 450 ? " long" : body.length > 180 ? " mid" : "")
    this.bodyTarget.textContent = body
    this.refTargets.forEach(r => r.textContent = `${this.refPrefixValue}:${n}`)
    this.tickTargets.forEach(t => t.classList.toggle("current", Number(t.dataset.number) === n))

    this.notesTargets.forEach(el => { el.hidden = Number(el.dataset.number) !== n })
    this.unitFieldTarget.value = this.currentNotes?.dataset.unitId
    this.updateCount()
  }

  get currentNotes() {
    return this.notesTargets.find(el => Number(el.dataset.number) === this.currentValue)
  }

  updateCount() {
    const count = this.currentNotes?.querySelectorAll(".note").length ?? 0
    this.countTarget.textContent = count ? `${count} note${count === 1 ? "" : "s"}` : "No notes yet"
    this.updateMarkers()
  }

  // The strip marks every verse that has notes.
  updateMarkers() {
    this.notesTargets.forEach(el => {
      const n = Number(el.dataset.number)
      const count = el.querySelectorAll(".note").length
      const tick = this.tickTargets.find(t => Number(t.dataset.number) === n)
      if (!tick) return
      tick.classList.toggle("has", count > 0)
      tick.setAttribute("aria-label", count ? `Verse ${n}, ${count} note${count === 1 ? "" : "s"}` : `Verse ${n}`)
    })
  }

  fillNear(el, number) {
    el.replaceChildren()
    if (number === undefined) return
    const b = document.createElement("b")
    b.textContent = number
    el.append(b, this.bodies.get(number))
  }

  touchStart(event) { this.touchX = event.touches[0].clientX }

  touchEnd(event) {
    if (this.touchX === undefined) return
    const dx = event.changedTouches[0].clientX - this.touchX
    this.touchX = undefined
    if (Math.abs(dx) > 60) this.step(dx < 0 ? 1 : -1)
  }

  key(event) {
    if (event.target.closest("input, textarea, [contenteditable]") || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "ArrowRight" || event.key === "j") this.next()
    if (event.key === "ArrowLeft" || event.key === "k") this.previous()
  }
}
