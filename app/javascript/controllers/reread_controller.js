import { Controller } from "@hotwired/stimulus"
import { csrfToken, fillId } from "lib/request"

const VIEW_KEY = "reread-labels-view"

// Rereading a focus's notes: one lit at a time down the column (j/k, the arrows, or a click), labelled with + label (l)
// or from the labels panel (c), which shows the labels in use as a cloud or as tallies. Pointing at a label lights the
// notes that carry it. The current focus's note you're on gets the reader's editor; where you are is saved, so the
// reread opens there again.
export default class extends Controller {
  static targets = ["row", "slot", "noteLabels", "labelsBody", "picker", "pickerInput", "pickerOptions", "labelForm", "pad", "labelsPanel"]
  static values = { positionUrl: String, labelsUrlTemplate: String, editorUrlTemplate: String }

  connect() {
    let view = "cloud"
    try { view = localStorage.getItem(VIEW_KEY) || view } catch {}
    this.#setView(view)
    if (this.here) {
      this.here.scrollIntoView({ block: "center" })
      this.#openEditor()
    }
    this.#mark()
  }

  disconnect() {
    clearTimeout(this.saveTimer)
  }

  // A note's chips or the panel were redrawn (labelling replies with both).
  noteLabelsTargetConnected() { this.#mark() }
  labelsBodyTargetConnected() { this.#mark() }

  get here() { return this.rowTargets.find(row => row.classList.contains("here")) }

  // ---------- moving ----------

  next() { this.#step(1) }
  previous() { this.#step(-1) }

  pick(event) {
    const row = event.currentTarget
    if (row.classList.contains("here") || event.target.closest("a, button")) return
    this.#go(row)
  }

  #step(by) {
    const rows = this.rowTargets
    const to = rows[rows.indexOf(this.here) + by]
    if (to) this.#go(to)
  }

  #go(row) {
    this.#closePicker()
    this.here?.classList.remove("here")
    row.classList.add("here")
    row.scrollIntoView({ block: "center", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" })
    this.#openEditor()
    this.#mark()
    this.#savePosition()
  }

  // The reader's note editor, in the row you're on (current focus only). The old frame goes, so its editor saves as it
  // disconnects, and a new one loads for this note.
  #openEditor() {
    if (!this.editorUrlTemplateValue) return
    this.element.querySelector("turbo-frame#note_editor")?.remove()
    const frame = document.createElement("turbo-frame")
    frame.id = "note_editor"
    frame.src = fillId(this.editorUrlTemplateValue, this.here.dataset.unitId)
    this.here.querySelector("[data-reread-target=slot]").append(frame)
  }

  // Tell the server where the reread is (debounced), so it opens here next time.
  #savePosition() {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      fetch(this.positionUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ note_id: this.here.dataset.noteId }),
        keepalive: true
      })
    }, 600)
  }

  // ---------- labelling ----------

  // Every label the user has: the panel lists them all (those under other focuses too).
  get #labels() {
    const seen = new Map()
    this.labelsPanelTarget.querySelectorAll(".rr-cloud [data-label-name]").forEach(word => {
      seen.set(word.dataset.labelName, { id: word.dataset.labelId, away: word.classList.contains("away"), title: word.title })
    })
    return seen
  }

  get #hereLabelIds() {
    return (this.here?.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").filter(Boolean)
  }

  toggleLabel(event) {
    const id = event.currentTarget.dataset.labelId
    if (!this.here) return
    if (this.#hereLabelIds.includes(id)) this.#submit("delete", id)
    else this.#submit("post", null, this.labelsPanelTarget.querySelector(`[data-label-id="${id}"][data-label-name]`).dataset.labelName)
  }

  unlabel(event) {
    event.stopPropagation()
    this.#submit("delete", event.currentTarget.dataset.labelId)
  }

  #submit(method, labelId, name) {
    const form = this.labelFormTarget
    const base = fillId(this.labelsUrlTemplateValue, this.here.dataset.noteId)
    form.action = labelId ? `${base}/${labelId}` : base
    form.querySelector("[name=_method]")?.remove()
    if (method === "delete") form.insertAdjacentHTML("beforeend", '<input type="hidden" name="_method" value="delete">')
    form.querySelector("[name=name]").value = name || ""
    form.requestSubmit()
  }

  // ---------- the picker ----------

  openPicker(event) {
    event?.stopPropagation()
    const add = this.here?.querySelector(".rr-add")
    if (!add) return
    const picker = this.pickerTarget
    const col = picker.offsetParent || picker.parentElement
    const box = add.getBoundingClientRect(), colBox = col.getBoundingClientRect()
    picker.style.left = `${box.left - colBox.left}px`
    picker.style.top = `${box.bottom - colBox.top + col.scrollTop + 6}px`
    picker.hidden = false
    this.pickerInputTarget.value = ""
    this.selected = 0
    this.filterPicker()
    this.pickerInputTarget.focus()
  }

  filterPicker() {
    const typed = this.pickerInputTarget.value.trim().replace(/\s+/g, " ")
    const q = typed.toLowerCase()
    const on = this.#hereLabelIds
    const options = [...this.#labels].filter(([name, { id }]) => !on.includes(id) && name.toLowerCase().includes(q))
      .sort(([a, x], [b, y]) => x.away - y.away || a.localeCompare(b))
      .map(([name, { away, title }]) => ({ name, note: away ? title.replace(/^[^:]*: /, "") : "" }))
    if (typed && ![...this.#labels.keys()].some(name => name.toLowerCase() === q)) options.push({ name: typed, note: "new label" })
    this.options = options
    this.selected = Math.min(this.selected || 0, Math.max(0, options.length - 1))
    this.pickerOptionsTarget.replaceChildren(...options.map((option, i) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "rr-option"
      button.setAttribute("role", "option")
      button.setAttribute("aria-selected", i === this.selected)
      button.append(option.note === "new label" ? `New label “${option.name}”` : option.name)
      if (option.note && option.note !== "new label") {
        const small = document.createElement("small")
        small.textContent = option.note
        button.append(small)
      }
      button.addEventListener("click", () => this.#choose(option.name))
      return button
    }))
    if (!options.length) this.pickerOptionsTarget.innerHTML = `<p class="rr-option-none">Type a name for a new label</p>`
  }

  pickerKey(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const n = this.options.length
      if (!n) return
      this.selected = (this.selected + (event.key === "ArrowDown" ? 1 : -1) + n) % n
      this.pickerOptionsTarget.querySelectorAll(".rr-option").forEach((b, i) => b.setAttribute("aria-selected", i === this.selected))
    } else if (event.key === "Enter") {
      event.preventDefault()
      const option = this.options[this.selected]
      if (option) this.#choose(option.name)
    } else if (event.key === "Escape") {
      event.stopPropagation()
      this.#closePicker()
    }
  }

  #choose(name) {
    this.#closePicker()
    this.#submit("post", null, name)
  }

  #closePicker() {
    if (this.pickerTarget.hidden) return
    this.pickerTarget.hidden = true
    if (this.pickerTarget.contains(document.activeElement)) document.activeElement.blur()
  }

  away(event) {
    if (!this.pickerTarget.hidden && !this.pickerTarget.contains(event.target) && !event.target.closest(".rr-add")) this.#closePicker()
  }

  // ---------- the labels panel ----------

  toggleLabels() {
    const open = !this.padTarget.classList.contains("labels-open")
    this.padTarget.classList.toggle("labels-open", open)
    this.element.querySelectorAll(".rr-summon").forEach(b => b.setAttribute("aria-expanded", open))
  }

  view(event) {
    this.#setView(event.currentTarget.dataset.view)
    try { localStorage.setItem(VIEW_KEY, event.currentTarget.dataset.view) } catch {}
  }

  #setView(view) {
    this.padTarget.classList.toggle("show-tallies", view === "tallies")
    this.element.querySelectorAll("[data-view]").forEach(b => b.setAttribute("aria-pressed", b.dataset.view === view))
  }

  // The note you're on: its labels marked in the panel, its tick in the tallies taller.
  #mark() {
    const on = this.#hereLabelIds
    const noteId = this.here?.dataset.noteId
    this.labelsPanelTarget.querySelectorAll("[data-label-id]").forEach(el => el.classList.toggle("on", on.includes(el.dataset.labelId)))
    this.labelsPanelTarget.querySelectorAll(".rr-ticks i").forEach(tick => tick.classList.toggle("here", tick.dataset.noteId === noteId))
  }

  // Pointing at a label (in the panel) lights the notes that carry it.
  light(event) {
    const word = event.target.closest?.(".rr-labels-panel [data-label-id]")
    const id = word?.dataset.labelId
    if (id === this.lit) return
    this.lit = id
    this.element.classList.toggle("lighting", !!id)
    this.rowTargets.forEach(row => {
      const ids = (row.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ")
      row.classList.toggle("lit", !!id && ids.includes(id))
    })
  }

  // ---------- keys ----------

  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "Escape" && this.padTarget.classList.contains("labels-open") && this.pickerTarget.hidden) return this.toggleLabels()
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    if (event.key === "j" || event.key === "ArrowRight") { event.preventDefault(); this.next() }
    else if (event.key === "k" || event.key === "ArrowLeft") { event.preventDefault(); this.previous() }
    else if (event.key === "l") { event.preventDefault(); this.openPicker() }
    else if (event.key === "c") { event.preventDefault(); this.toggleLabels() }
    else if (event.key === "e") { const editor = this.here?.querySelector("lexxy-editor [contenteditable]"); if (editor) { event.preventDefault(); focusAtEnd(editor) } }
    else if (event.key === "s") {
      const pad = this.padTarget.querySelector(".composer lexxy-editor [contenteditable]")
      if (!pad) return
      event.preventDefault()
      if (!this.padTarget.classList.contains("open") && matchMedia("(max-width: 899px)").matches) this.padTarget.querySelector(".panel-handle").click()
      focusAtEnd(pad)
    }
  }
}

// Into an editor with the caret after what's written, to add to it.
function focusAtEnd(editable) {
  editable.focus()
  const range = document.createRange()
  range.selectNodeContents(editable)
  range.collapse(false)
  const selection = getSelection()
  selection.removeAllRanges()
  selection.addRange(range)
}
