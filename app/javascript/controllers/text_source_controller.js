import { Controller } from "@hotwired/stimulus"

// The Add a text form: a chosen or dropped .txt / .md file is read in the browser into the text box (only text is
// sent), and the box shows how much it holds against the limit. Text that looks like verse, added as prose, gets a
// hint offering to read it as poetry.
const LIMIT = 5 * 1024 * 1024

// As UserText#looks_like_verse?: mostly short lines, many without a closing stop.
function looksLikeVerse(text) {
  const lines = text.split("\n").map(l => l.trim()).filter(l => l && !/^# /.test(l))
  if (lines.length < 6) return false
  const short = lines.filter(l => l.length <= 60).length
  const open = lines.filter(l => !/[.?!][”’")\]]*$/.test(l)).length
  return short > lines.length * 0.8 && open > lines.length * 0.4
}

export default class extends Controller {
  static targets = ["title", "source", "file", "stats", "error", "prose", "poetry", "hint"]

  connect() { this.count() }

  choose() { this.fileTarget.click() }
  pick(event) { this.take(event.target.files[0]) }

  over(event) { event.preventDefault(); this.element.classList.add("dropping") }
  leave() { this.element.classList.remove("dropping") }
  drop(event) {
    event.preventDefault()
    this.leave()
    this.take(event.dataTransfer.files[0])
  }

  take(file) {
    if (!file) return
    if (!/\.(txt|md|markdown)$/i.test(file.name) && !/^text\//.test(file.type)) return this.fail("Only plain text (.txt or .md) for now.")
    if (file.size > LIMIT) return this.fail("That file is over 5 MB.")
    file.text().then(text => {
      this.sourceTarget.value = text
      if (!this.titleTarget.value.trim()) this.titleTarget.value = file.name.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
      this.fail("")
      this.count()
    })
  }

  poetry() {
    this.poetryTarget.checked = true
    this.count()
  }

  count() {
    const text = this.sourceTarget.value
    if (this.hasHintTarget) this.hintTarget.hidden = !this.proseTarget.checked || this.proseTarget.disabled || !looksLikeVerse(text)
    if (!text.trim()) { this.statsTarget.textContent = ""; return }
    const words = (text.match(/\S+/g) || []).length
    const kb = new Blob([text]).size / 1024
    this.statsTarget.textContent = `${words.toLocaleString()} words · ${kb < 1024 ? `${kb.toFixed(1)} KB` : `${(kb / 1024).toFixed(1)} MB`} of 5 MB`
  }

  fail(message) { this.errorTarget.textContent = message }
}
