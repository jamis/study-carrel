import { Controller } from "@hotwired/stimulus"

// The review of a text being added: pick a sentence or stanza (or a "Worth a look" item) to see it as the reader will
// show it, and step through with ← →. On phones the preview slides up from the bottom when a sentence is picked.
export default class extends Controller {
  static targets = ["preview", "ref", "text", "of", "prev", "next"]

  connect() {
    this.sentences = [...this.element.querySelectorAll(".s[data-key]")]
    this.show(0)
  }

  pick(event) { this.show(this.sentences.indexOf(event.currentTarget), { open: true }) }

  jump(event) {
    const i = this.sentences.findIndex(s => s.dataset.key === event.currentTarget.dataset.sentence)
    if (i >= 0) this.show(i, { scroll: true, open: true })
  }

  previous() { this.show(this.index - 1, { scroll: true }) }
  next() { this.show(this.index + 1, { scroll: true }) }
  close() { this.previewTarget.classList.remove("open") }

  key(event) {
    if (event.target.closest("input, textarea, button, summary")) return
    if (event.key === "ArrowLeft") { this.previous(); event.preventDefault() }
    if (event.key === "ArrowRight") { this.next(); event.preventDefault() }
    if (event.key === "Escape") this.close()
  }

  show(i, { scroll = false, open = false } = {}) {
    if (!this.sentences.length) return
    this.index = Math.max(0, Math.min(this.sentences.length - 1, i))
    const el = this.sentences[this.index]
    this.element.querySelectorAll(".s.here").forEach(s => s.classList.remove("here"))
    el.classList.add("here")
    if (scroll) el.scrollIntoView({ block: "center", behavior: "smooth" })

    const text = [...el.childNodes].filter(n => n.nodeName !== "SUP" && !n.classList?.contains("pn")).map(n => n.textContent).join("")
    const length = text.length
    this.refTarget.textContent = el.dataset.ref
    this.textTarget.style.fontSize = el.classList.contains("texts-stanza")
      ? (length < 160 ? "23px" : length < 320 ? "20px" : "17px")
      : (length < 120 ? "28px" : length < 300 ? "24px" : length < 600 ? "21px" : "18px")
    this.textTarget.replaceChildren()
    if (el.dataset.first === "true") {
      const mark = document.createElement("span")
      mark.className = "pilcrow"
      mark.setAttribute("aria-hidden", "true")
      mark.textContent = "¶"
      this.textTarget.append(mark)
    }
    this.textTarget.append(text)
    this.ofTarget.textContent = el.dataset.of
    this.prevTarget.disabled = this.index === 0
    this.nextTarget.disabled = this.index === this.sentences.length - 1
    if (open) this.previewTarget.classList.add("open")
  }
}
