import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken, fillId } from "lib/request"

// Finding what goes with a note, on the reread page (alongside the reread controller): g, or "Find what goes with this"
// on the note you're on. The note you're on is held at the top of the column, its groups (its labels, named or not)
// numbered for the moment and each shown by its face; every other note of the focus is listed under it, each with a
// button per group and + for a new group of the two. A note is always grouped from the held note's side: you choose
// among its groups, never the other note's, so a note already in several just gains one more.
//
// The card is kept short: the passage cut to a line, the note to five, each face to one; what's cut off opens over
// what's below (hover, a tap, or p and o). A number pointed at on a row lights its group in the card; a group pointed
// at in the card lights its notes in the list. g, Esc or the card's × goes back to the reread, on the note you're on.
export default class extends Controller {
  static targets = ["card", "labels", "noteLabels"]
  static values = { labelsUrlTemplate: String, renameUrlTemplate: String }

  connect() {
    this.canHover = matchMedia("(hover: hover)").matches
    this.cursor = null
    this.naming = null
    // How much of the top the card covers, so a row moved to is scrolled out from under it.
    this.resized = new ResizeObserver(() => this.#covered())
    this.resized.observe(this.cardTarget)
    this.onResize = () => this.#covered()
    addEventListener("resize", this.onResize)
    this.element.addEventListener("click", this.clicked = event => this.#click(event))
    this.element.addEventListener("mouseover", this.pointed = event => this.#point(event))
    document.addEventListener("click", this.away = event => this.#away(event))
  }

  disconnect() {
    this.resized.disconnect()
    removeEventListener("resize", this.onResize)
    this.element.removeEventListener("click", this.clicked)
    this.element.removeEventListener("mouseover", this.pointed)
    document.removeEventListener("click", this.away)
  }

  get comparing() { return this.element.classList.contains("comparing") }
  get #reread() { return this.application.getControllerForElementAndIdentifier(this.element, "reread") }
  get #here() { return this.element.querySelector(".rr-row.here") }
  // The focus's notes that are saved (a new note being written isn't one yet), in the column's order.
  get #rows() { return [...this.element.querySelectorAll(".rr-row[data-note-id]")].filter(row => row.dataset.noteId) }
  get #others() { return this.#rows.filter(row => row !== this.#here) }

  // ---------- in and out ----------

  enter(event) {
    event?.stopPropagation()
    if (this.comparing || !this.#here?.dataset.noteId) return
    this.element.classList.add("comparing")
    this.cardTarget.hidden = false
    this.cursor = null
    this.#render()
    scrollTo({ top: 0 })
  }

  leave() {
    if (!this.comparing) return
    this.element.classList.remove("comparing", "cmp-lighting")
    this.cardTarget.hidden = true
    this.cardTarget.replaceChildren()
    this.#rows.forEach(row => row.classList.remove("cursor", "cmp-lit"))
    this.cursor = null
    this.naming = null
    this.#reread?.centre()
  }

  // A row's chips or the labels panel were redrawn by a reply: draw again, once.
  noteLabelsTargetConnected() { this.#soon() }
  labelsTargetConnected() { this.#soon() }

  #soon() {
    if (!this.comparing || this.pending) return
    this.pending = requestAnimationFrame(() => { this.pending = null; if (this.comparing) this.#render() })
  }

  // ---------- drawing ----------

  get #labels() {
    try { return new Map(JSON.parse(this.labelsTarget.textContent).map(label => [String(label.id), label])) } catch { return new Map() }
  }

  #idsOf(row) { return (row?.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").filter(Boolean) }

  // The held note's groups, in the order they were made, so their numbers stay put as notes join them.
  get #mine() {
    const labels = this.#labels
    return this.#idsOf(this.#here).map(id => labels.get(id)).filter(Boolean).sort((a, b) => a.id - b.id)
  }

  #render() {
    this.#renderCard()
    this.#renderRows()
    this.#mark()
    this.#covered()
  }

  #renderCard() {
    const here = this.#here, rows = this.#rows, mine = this.#mine
    if (!here) return this.leave()
    const cite = here.dataset.cite || ""
    const passage = here.querySelector(".rr-passage")?.textContent.trim()
    const note = here.querySelector(".rr-note")?.innerHTML || ""
    const at = rows.indexOf(here) + 1
    const groups = mine.map((label, i) => {
      const face = String(label.example) === here.dataset.noteId ? label.alt : label.face
      const others = rows.filter(row => row !== here && this.#idsOf(row).includes(String(label.id)))
      const naming = this.naming === String(label.id)
      return `<li class="cmp-group" data-label-id="${label.id}" style="--c: var(--g${label.hue})">
        <span class="cmp-num">${i + 1}</span>
        <span class="cmp-g-body">
          ${naming
            ? `<input class="cmp-name" type="text" maxlength="40" value="${escapeHtml(label.named ? stripTags(label.face) : "")}" placeholder="Words for it (optional)" aria-label="Name"><span class="cmp-name-error" hidden></span>`
            : peek("face", face, "span")}
          <span class="cmp-with">${others.length ? `with ${others.map(row => `<button type="button" class="cmp-jump" data-note-id="${row.dataset.noteId}">${escapeHtml(shortCite(row.dataset.cite, cite))}</button>`).join(", ")}` : "just this note, so far"}</span>
          <span class="cmp-g-acts">${naming ? "" : `<button type="button" data-name="${label.id}">${label.named ? "rename" : "name it"}</button> · `}<button type="button" data-leave="${label.id}" title="Take this note out of the group">take out</button></span>
        </span>
      </li>`
    }).join("")
    const hint = mine.length === 1 ? "; <kbd>1</kbd> puts it in this one" : mine.length ? `; <kbd>1</kbd>–<kbd>${Math.min(mine.length, 9)}</kbd> put it in one of these` : ""

    this.cardTarget.innerHTML = `
      <div class="cmp-step">
        <button type="button" data-step="-1" aria-label="The note before">‹</button> ${at} of ${rows.length} <button type="button" data-step="1" aria-label="The note after">›</button>
        <span class="cmp-step-keys"><kbd>J</kbd>/<kbd>K</kbd></span>
        <button type="button" class="cmp-close" aria-label="Back to the reread" title="Back to the reread (g)">×</button>
      </div>
      <div class="rr-ref${here.classList.contains("rr-free") ? " rr-whole" : ""}">${escapeHtml(here.querySelector(".rr-cite")?.textContent || here.querySelector(".rr-ref")?.textContent || cite)}</div>
      ${passage ? peek("passage", `<p class="rr-passage">${escapeHtml(passage)}</p>`) : ""}
      ${peek("note", `<div class="rr-note">${note}</div>`)}
      <h2 class="cmp-gw">Goes with</h2>
      <ol class="cmp-groups">
        ${groups}
        <li class="cmp-new">${mine.length ? "" : "Nothing yet. "}On a note below, <kbd>+</kbd> starts a new group of the two${hint}.</li>
      </ol>`

    // Only what's cut off can be opened.
    this.cardTarget.querySelectorAll(".peek").forEach(peek => {
      const cut = peek.matches(".peek-face") ? peek.firstElementChild : peek.firstElementChild.firstElementChild
      peek.classList.toggle("fits", cut.scrollHeight <= cut.clientHeight + 1)
    })
    this.opened = null
    const input = this.cardTarget.querySelector(".cmp-name")
    if (input) {
      input.focus()
      input.select()
      input.addEventListener("keydown", event => this.#nameKey(event))
    }
  }

  // Each other note's buttons: one per held group (filled when it's in it) and + for a new group of the two.
  #renderRows() {
    const mine = this.#mine, hereIds = this.#idsOf(this.#here)
    this.#others.forEach(row => {
      const ids = this.#idsOf(row)
      let acts = row.querySelector(".rr-cmp-acts")
      if (!acts) {
        acts = document.createElement("span")
        acts.className = "rr-cmp-acts"
        row.querySelector(".rr-head").append(acts)
      }
      acts.innerHTML = mine.map((label, i) => {
        const on = ids.includes(String(label.id))
        return `<button type="button" class="cmp-put${on ? " on" : ""}" data-put="${label.id}" style="--c: var(--g${label.hue})" aria-pressed="${on}" title="${on ? "Take it out of" : "Put it in"} group ${i + 1}">${i + 1}</button>`
      }).join("") + '<button type="button" class="cmp-put cmp-plus" data-plus title="A new group of these two">+</button>'
      row.classList.toggle("along", ids.some(id => hereIds.includes(id)))
      row.classList.toggle("cursor", row.dataset.noteId === this.cursor)
    })
  }

  // The groups the row at the cursor is already in, marked in the card; hot: the group of a number pointed at.
  #mark(hot = null) {
    const row = this.#rowOf(this.cursor)
    const ids = this.#idsOf(row)
    this.cardTarget.querySelectorAll(".cmp-group").forEach(li => {
      const has = !!row && ids.includes(li.dataset.labelId)
      li.classList.toggle("hot", li.dataset.labelId === hot)
      li.classList.toggle("has", has)
      const with_ = li.querySelector(".cmp-with")
      if (with_) with_.dataset.has = has ? shortCite(row.dataset.cite, this.#here?.dataset.cite || "") : ""
    })
  }

  #rowOf(noteId) { return noteId ? this.#rows.find(row => row.dataset.noteId === noteId) : null }

  #covered() {
    if (!this.comparing) return
    const top = parseFloat(getComputedStyle(this.cardTarget).top) || 0
    this.element.style.setProperty("--covered", `${top + this.cardTarget.offsetHeight + 12}px`)
  }

  // ---------- the cut-off text ----------

  #open(peek) {
    if (this.opened && this.opened !== peek) this.opened.classList.remove("open")
    this.opened = peek && !peek.classList.contains("fits") ? peek : null
    this.opened?.classList.add("open")
  }

  #closePeeks() {
    const was = !!this.opened?.isConnected
    this.#open(null)
    return was
  }

  // ---------- pointing and clicking ----------

  #point(event) {
    if (!this.comparing) return
    const inCard = this.cardTarget.contains(event.target)
    if (this.canHover) {
      const peek = inCard && event.target.closest(".peek")
      if (peek) this.#open(peek)
      else if (this.opened) this.#closePeeks()
    }
    // A number on a row lights its group in the card; a group in the card lights its notes in the list.
    this.#mark(event.target.closest?.(".rr-cmp-acts [data-put]")?.dataset.put || null)
    const group = inCard ? event.target.closest(".cmp-group[data-label-id]")?.dataset.labelId : null
    if (group === this.lighting) return
    this.lighting = group
    this.element.classList.toggle("cmp-lighting", !!group)
    this.#others.forEach(row => row.classList.toggle("cmp-lit", !!group && this.#idsOf(row).includes(group)))
  }

  #away(event) {
    if (this.comparing && !this.canHover && this.opened && !this.opened.contains(event.target)) this.#closePeeks()
  }

  #click(event) {
    if (!this.comparing) return
    const t = event.target
    if (this.cardTarget.contains(t)) {
      if (t.closest(".cmp-close")) return this.leave()
      if (t.closest("[data-step]")) return this.#step(Number(t.closest("[data-step]").dataset.step))
      if (t.closest(".cmp-jump")) return this.#moveTo(this.#rowOf(t.closest(".cmp-jump").dataset.noteId))
      if (t.closest("[data-name]")) { this.naming = t.closest("[data-name]").dataset.name; return this.#renderCard() }
      if (t.closest("[data-leave]")) return this.#put(t.closest("[data-leave]").dataset.leave, this.#here)
      if (!this.canHover && t.closest(".peek")) {
        const peek = t.closest(".peek")
        return peek === this.opened ? this.#closePeeks() : this.#open(peek)
      }
      return
    }
    const row = t.closest(".rr-row")
    if (!row || row === this.#here || !row.dataset.noteId || t.closest("a")) return
    if (t.closest("[data-put]")) return this.#put(t.closest("[data-put]").dataset.put, row)
    if (t.closest("[data-plus]")) return this.#plus(row)
    if (t.closest("button")) return
    this.cursor = row.dataset.noteId
    this.#renderRows()
    this.#mark()
  }

  // ---------- moving ----------

  #moveCursor(by) {
    const others = this.#others
    const at = others.findIndex(row => row.dataset.noteId === this.cursor)
    const to = others[at < 0 ? (by > 0 ? 0 : others.length - 1) : Math.max(0, Math.min(others.length - 1, at + by))]
    if (!to) return
    this.cursor = to.dataset.noteId
    this.#renderRows()
    this.#mark()
    to.scrollIntoView({ block: "nearest", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" })
  }

  #step(by) {
    const rows = this.#rows
    this.#moveTo(rows[rows.indexOf(this.#here) + by])
  }

  // Another note becomes the one you're on (the reread's own move, so where you are is kept).
  #moveTo(row) {
    if (!row || row === this.#here) return
    this.#reread?.goTo(row)
    this.cursor = null
    this.naming = null
    this.#render()
    scrollTo({ top: 0, behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" })
  }

  // ---------- grouping ----------

  #put(labelId, row) {
    const on = this.#idsOf(row).includes(String(labelId))
    const base = fillId(this.labelsUrlTemplateValue, row.dataset.noteId)
    if (on) this.#send("DELETE", `${base}/${labelId}`)
    else this.#send("POST", base, { label_id: labelId })
  }

  #plus(row) {
    this.#send("POST", fillId(this.labelsUrlTemplateValue, this.#here.dataset.noteId), { with_note_id: row.dataset.noteId })
  }

  async #rename(labelId, name) {
    const refusal = await this.#send("PATCH", fillId(this.renameUrlTemplateValue, labelId), { name })
    if (refusal) {
      const error = this.cardTarget.querySelector(".cmp-name-error")
      if (error) { error.textContent = refusal; error.hidden = false }
      return
    }
    this.naming = null
    this.#render()
  }

  #nameKey(event) {
    event.stopPropagation()
    if (event.key === "Enter") { event.preventDefault(); this.#rename(this.naming, event.target.value) }
    else if (event.key === "Escape") { event.preventDefault(); this.naming = null; this.#renderCard(); this.#mark() }
  }

  // Sends a change; the reply redraws the chips and the panel, and so this. Returns why it was refused, if it was.
  async #send(method, url, body = {}) {
    const response = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": csrfToken() },
      body: method === "DELETE" ? undefined : JSON.stringify(body)
    })
    if (!response.ok) return response.status === 422 ? (await response.text()) || "That couldn't be done." : "That couldn't be done."
    Turbo.renderStreamMessage(await response.text())
    return null
  }

  // ---------- keys ----------

  // g in and out; while comparing: j/k through the others, 1–9 put the one you're at in a group (again to take it out),
  // + or n a new group of the two, Enter makes it the note you're on, J/K step the note you're on, p and o open the
  // passage and the note, Esc closes what's open, then goes back.
  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest?.("input, textarea, select, [contenteditable]")) return
    const k = event.key
    if (!this.comparing) {
      if (k === "g" && !event.repeat && this.#here?.dataset.noteId) { event.preventDefault(); this.enter() }
      return
    }
    if (k === "g" || (k === "Escape" && !this.#closePeeks())) { event.preventDefault(); return this.leave() }
    if (k === "Escape") return event.preventDefault()
    const cursor = this.#rowOf(this.cursor)
    if (event.repeat && "jkJK".includes(k)) return event.preventDefault()
    if (k === "j" || k === "ArrowDown") this.#moveCursor(1)
    else if (k === "k" || k === "ArrowUp") this.#moveCursor(-1)
    else if (k === "J" || k === "ArrowRight") this.#step(1)
    else if (k === "K" || k === "ArrowLeft") this.#step(-1)
    else if (/^[1-9]$/.test(k) && cursor) { const label = this.#mine[Number(k) - 1]; if (label) this.#put(label.id, cursor) }
    else if ((k === "+" || k === "=" || k === "n") && cursor) this.#plus(cursor)
    else if (k === "Enter" && cursor) this.#moveTo(cursor)
    else if (k === "p" || k === "o") {
      const peek = this.cardTarget.querySelector(k === "p" ? ".peek-passage" : ".peek-note")
      peek && peek === this.opened ? this.#closePeeks() : this.#open(peek)
    }
    else return
    event.preventDefault()
  }
}

// Cut-off text: the cut copy in place, and the whole of it laid over it when opened.
function peek(kind, html, tag = "div") {
  return `<${tag} class="peek peek-${kind}"><${tag} class="peek-cut">${html}</${tag}><${tag} class="peek-full">${html}</${tag}></${tag}>`
}

// "Isaiah 40:6" beside "Isaiah 40:7" is just "40:6"; from another work or chapter, the whole of it.
function shortCite(cite = "", from = "") {
  const split = text => { const at = text.lastIndexOf(" "); return at < 0 ? [ "", text ] : [ text.slice(0, at), text.slice(at + 1) ] }
  const [ book, rest ] = split(cite), [ fromBook ] = split(from)
  return book && book === fromBook ? rest : cite
}

const escapeHtml = text => String(text).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
const stripTags = html => { const div = document.createElement("div"); div.innerHTML = html; return div.textContent.trim() }
