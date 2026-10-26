import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { csrfToken, fillId } from "lib/request"
import { citeOf, shortCite, condensedCite, labelIdsOf, escapeHtml } from "lib/notes"

const MAX_TABS = 3

// Gathering what goes with a note, on the reread page (alongside the reread and peek controllers): g, or "Gather"
// on the note you're on. The note you're on is held on a card at the top of the column, its groups (its labels, named
// or not) numbered for the moment and each shown by its face; every other note of the focus is
// listed under it, each with a button per group and + for a new group of the two. A note is always grouped from the
// held note's side: you choose among its groups, never the other note's, so a note already in several just gains one.
//
// Up to three notes are held at once, under tabs along the card's top: "Hold this" on a row (Enter) holds that note
// under a tab of its own, the one used longest ago giving way, without the list moving. A tab ([ and ]) goes back to its
// note, and the list to where it was when that note was last the one you were on. x, or a tab's ×, lets one go.
//
// The card is kept short: the passage cut to a line, the note to three, each face to one; what's cut off opens over
// what's below (hover, a tap, or p and o). A number pointed at on a row lights its group in the card; a group pointed
// at in the card lights its notes in the list. g, Esc or the card's × goes back to the reread, on the note you're on.
export default class extends Controller {
  static targets = ["card", "labels", "noteLabels"]
  static values = { labelsUrlTemplate: String, renameUrlTemplate: String }

  connect() {
    this.canHover = matchMedia("(hover: hover)").matches
    this.cursor = null
    this.naming = null
    // The held notes, a tab each: { id, used (which gives way), place (the row in sight when last left, and where) }.
    this.tabs = []
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
  get #active() { return this.tabs.findIndex(tab => tab.id === this.#here?.dataset.noteId) }
  get #motion() { return matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" }

  // ---------- in and out ----------

  enter(event) {
    event?.stopPropagation()
    const here = this.#here
    if (this.comparing || !here?.dataset.noteId) return
    this.element.classList.add("comparing")
    this.cardTarget.hidden = false
    this.cursor = null
    // The tabs held last time stay, so long as their notes do; the note you're on is held too.
    this.tabs = this.tabs.filter(tab => this.#rowOf(tab.id))
    this.#addTab(here.dataset.noteId)
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

  // ---------- holding ----------

  // Another note held, under a tab of its own: the note at the cursor (Enter), "Hold this" on a row, or "Hold it" from a
  // note shown from the card. One already held goes back to its tab.
  hold(row) {
    if (!this.comparing || !row?.dataset.noteId || row === this.#here) return
    const held = this.tabs.findIndex(tab => tab.id === row.dataset.noteId)
    if (held >= 0) return this.#switchTab(held)
    const wasCursor = this.cursor === row.dataset.noteId
    const leaving = this.tabs[this.#active]
    const kept = this.#keepPlace(row, () => {
      if (leaving) leaving.place = this.#place(row)
      this.#addTab(row.dataset.noteId)
      this.#moveTo(row)
    })
    if (wasCursor && kept) { this.cursor = kept; this.#renderRows(); this.#mark() }
  }

  // Holds a note under a new tab, at the end; with three already, the one used longest ago (not the one you're on)
  // gives way. One already held is only touched.
  #addTab(id) {
    const tab = this.tabs.find(tab => tab.id === id)
    if (tab) return (tab.used = Date.now())
    if (this.tabs.length >= MAX_TABS) {
      const here = this.#here?.dataset.noteId
      const oldest = this.tabs.filter(tab => tab.id !== here).sort((a, b) => a.used - b.used)[0]
      this.tabs.splice(this.tabs.indexOf(oldest), 1)
    }
    this.tabs.push({ id, used: Date.now(), place: null })
  }

  #switchTab(k) {
    const to = this.tabs[k], row = to && this.#rowOf(to.id)
    if (!row || row === this.#here) return
    const from = this.tabs[this.#active], place = this.#place(row)
    if (from) from.place = place
    to.used = Date.now()
    const back = to.place
    this.#moveTo(row)
    // The list as it was when this note was last the one you were on, the cursor where it was then; or, the first time,
    // as it is.
    if (back) { this.cursor = back.id; this.#renderRows(); this.#mark(); this.#restore(back) }
    else this.#restore(place)
  }

  // Lets a held note go; letting go of the last one leaves.
  #untab(k) {
    if (this.tabs.length <= 1) return this.leave()
    const [ gone ] = this.tabs.splice(k, 1)
    if (gone.id !== this.#here?.dataset.noteId) return this.#renderCard()
    const next = this.tabs[Math.min(k, this.tabs.length - 1)]
    const row = this.#rowOf(next.id), back = next.place
    this.#moveTo(row)
    if (back) this.#restore(back)
  }

  // ‹ › and J/K: the note under this tab steps along the run, past notes held under the other tabs, the list staying put.
  #step(by) {
    const rows = this.#rows, held = this.tabs.map(tab => tab.id)
    let at = rows.indexOf(this.#here) + by
    while (rows[at] && held.includes(rows[at].dataset.noteId)) at += by
    const row = rows[at]
    if (!row) return
    const tab = this.tabs[this.#active]
    this.#keepPlace(row, () => {
      if (tab) { tab.id = row.dataset.noteId; tab.place = null }
      this.#moveTo(row)
    })
  }

  // The note becomes the one you're on (the reread's own move, so where you are is kept), and everything is drawn
  // again.
  #moveTo(row) {
    this.#reread?.goTo(row)
    this.cursor = this.#rowOf(this.cursor) && this.cursor !== row.dataset.noteId ? this.cursor : null
    this.naming = null
    this.#render()
  }

  // ---------- keeping your place ----------

  // The row in sight just under the card, and where it is on screen. When the row about to be held is in sight, its
  // neighbour, which takes its place: so the list doesn't move when the note you're on changes.
  #place(leaving = null) {
    const rows = this.#others, under = this.#under
    const inSight = row => { const box = row.getBoundingClientRect(); return box.bottom > under && box.top < innerHeight }
    if (leaving && rows.includes(leaving) && inSight(leaving)) {
      const at = rows.indexOf(leaving), next = rows[at + 1] || rows[at - 1]
      return next && { id: next.dataset.noteId, top: leaving.getBoundingClientRect().top }
    }
    const candidates = rows.filter(row => row !== leaving && inSight(row))
    const row = candidates.find(row => row.dataset.noteId === this.cursor) || candidates.find(row => row.getBoundingClientRect().top >= under - 20) || candidates[0]
    return row && { id: row.dataset.noteId, top: row.getBoundingClientRect().top }
  }

  // The row back where it was on screen (or just under the card, if the card has grown over it).
  #restore(place) {
    const row = place && this.#rowOf(place.id)
    if (row) scrollBy(0, row.getBoundingClientRect().top - Math.max(place.top, this.#under + 12))
  }

  #keepPlace(leaving, change) {
    const place = this.#place(leaving)
    change()
    this.#restore(place)
    return place?.id
  }

  get #under() { return this.cardTarget.getBoundingClientRect().bottom }

  // ---------- drawing ----------

  get #labels() {
    try { return new Map(JSON.parse(this.labelsTarget.textContent).map(label => [String(label.id), label])) } catch { return new Map() }
  }

  // The held note's groups, in the order they were made, so their numbers stay put as notes join them.
  get #mine() {
    const labels = this.#labels
    return labelIdsOf(this.#here).map(id => labels.get(id)).filter(Boolean).sort((a, b) => a.id - b.id)
  }

  #render() {
    this.tabs = this.tabs.filter(tab => this.#rowOf(tab.id))
    this.#renderCard()
    this.#renderRows()
    this.#mark()
    this.#covered()
  }

  #renderCard() {
    const here = this.#here, rows = this.#rows, mine = this.#mine
    if (!here) return this.leave()
    const cite = citeOf(here)
    const passage = here.querySelector(".rr-passage")?.textContent.trim()
    const note = here.querySelector(".rr-note")?.innerHTML || ""
    const at = rows.indexOf(here) + 1
    const tabs = this.tabs.map((tab, k) => {
      const row = this.#rowOf(tab.id), on = row === here
      const words = (row.querySelector(".rr-note")?.textContent || "").trim().split(/\s+/).slice(0, 8).join(" ")
      return `<button type="button" role="tab" class="cmp-tab${on ? " on" : ""}" data-tab="${k}" aria-selected="${on}"${on ? "" : ` data-fn-note="${tab.id}" data-fn-peek`}>
        <span class="cmp-tab-ref" title="${escapeHtml(citeOf(row))}">${condensedCite(shortCite(citeOf(row), cite))}</span><span class="cmp-tab-words">${escapeHtml(words)}</span><span class="cmp-tab-x" data-untab="${k}" role="button" aria-label="Let it go" title="Let it go (x)">×</span>
      </button>`
    }).join("")
    const groups = mine.map((label, i) => {
      const others = rows.filter(row => row !== here && labelIdsOf(row).includes(String(label.id)))
      const naming = this.naming === String(label.id)
      return `<li class="cmp-group" data-label-id="${label.id}" style="--c: var(--g${label.hue})">
        <span class="cmp-num">${i + 1}</span>
        <span class="cmp-g-body">
          ${naming
            ? `<input class="cmp-name" type="text" maxlength="40" value="${escapeHtml(label.named ? stripTags(label.face) : "")}" placeholder="Words for it (optional)" aria-label="Name"><span class="cmp-name-error" hidden></span>`
            : peek("face", label.face, "span")}
          <span class="cmp-with">${others.length ? `with ${others.map(row => `<button type="button" class="cmp-jump" data-note-id="${row.dataset.noteId}" data-fn-note="${row.dataset.noteId}" data-fn-from="${here.dataset.noteId}" title="${escapeHtml(citeOf(row))}">${condensedCite(shortCite(citeOf(row), cite))}</button>`).join(", ")}` : "just this note, so far"}</span>
          <span class="cmp-g-acts">${naming ? "" : `<button type="button" data-name="${label.id}">${label.named ? "rename" : "name it"}</button> · `}<button type="button" data-leave="${label.id}" title="Take this note out of the group">take out</button></span>
        </span>
      </li>`
    }).join("")

    this.cardTarget.innerHTML = `
      <div class="cmp-tabs" role="tablist" aria-label="Held notes">
        ${tabs}
        <button type="button" class="cmp-close" aria-label="Back to the reread" title="Back to the reread (g)">×</button>
      </div>
      <div class="cmp-head">
        <div class="rr-ref${here.classList.contains("rr-free") ? " rr-whole" : ""}">${escapeHtml(here.querySelector(".rr-cite")?.textContent || cite)}</div>
        <span class="cmp-steps"><button type="button" data-step="-1" aria-label="The note before" title="The note before (K)">‹</button><span class="cmp-at">${at} of ${rows.length}</span><button type="button" data-step="1" aria-label="The note after" title="The note after (J)">›</button></span>
      </div>
      ${passage ? peek("passage", `<p class="rr-passage">${escapeHtml(passage)}</p>`) : ""}
      ${peek("note", `<div class="rr-note">${note}</div>`)}
      <ol class="cmp-groups">
        ${groups}
        ${mine.length ? "" : `<li class="cmp-new">In no group yet. On a note below, <kbd>+</kbd> starts one of the two.</li>`}
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

  // Each other note: "Hold this" by its reference, and a button per held group (filled when it's in it) and + for a
  // new group of the two.
  #renderRows() {
    const mine = this.#mine, hereIds = labelIdsOf(this.#here), held = this.tabs.map(tab => tab.id)
    this.#others.forEach(row => {
      const ids = labelIdsOf(row)
      let hold = row.querySelector(".rr-cmp-hold"), acts = row.querySelector(".rr-cmp-acts")
      if (!acts) {
        hold = document.createElement("button")
        hold.type = "button"
        hold.className = "rr-cmp-hold"
        row.querySelector(".rr-ref").after(hold)
        acts = document.createElement("span")
        acts.className = "rr-cmp-acts"
        row.querySelector(".rr-head").append(acts)
      }
      const isHeld = held.includes(row.dataset.noteId)
      hold.textContent = isHeld ? "Held · go to its tab" : "Hold this"
      hold.title = isHeld ? "" : "Hold it under a tab of its own (Enter)"
      hold.classList.toggle("rr-held", isHeld)
      acts.innerHTML = mine.map((label, i) => {
        const on = ids.includes(String(label.id))
        return `<button type="button" class="cmp-put${on ? " on" : ""}" data-put="${label.id}" style="--c: var(--g${label.hue})" aria-pressed="${on}" title="${on ? "Take it out of" : "Put it in"} group ${i + 1}">${i + 1}</button>`
      }).join("") + '<button type="button" class="cmp-put cmp-plus" data-plus title="A new group of these two">+</button>'
      row.classList.toggle("along", ids.some(id => hereIds.includes(id)))
      row.classList.toggle("cursor", row.dataset.noteId === this.cursor)
    })
  }

  // The groups the row at the cursor is already in, ringed in the card, and its reference picked out among each one's
  // notes; hot: the group of a number pointed at.
  #mark(hot = null) {
    const row = this.#rowOf(this.cursor)
    const ids = labelIdsOf(row)
    this.cardTarget.querySelectorAll(".cmp-group").forEach(li => {
      li.classList.toggle("hot", li.dataset.labelId === hot)
      li.classList.toggle("has", !!row && ids.includes(li.dataset.labelId))
      li.querySelectorAll(".cmp-jump").forEach(jump => jump.classList.toggle("at", jump.dataset.noteId === this.cursor))
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
    this.#others.forEach(row => row.classList.toggle("cmp-lit", !!group && labelIdsOf(row).includes(group)))
  }

  #away(event) {
    if (this.comparing && !this.canHover && this.opened && !this.opened.contains(event.target)) this.#closePeeks()
  }

  #click(event) {
    if (!this.comparing) return
    const t = event.target
    if (this.cardTarget.contains(t)) {
      if (t.closest(".cmp-close")) return this.leave()
      if (t.closest("[data-untab]")) return this.#untab(Number(t.closest("[data-untab]").dataset.untab))
      if (t.closest("[data-tab]")) return this.#switchTab(Number(t.closest("[data-tab]").dataset.tab))
      if (t.closest("[data-step]")) return this.#step(Number(t.closest("[data-step]").dataset.step))
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
    if (t.closest(".rr-cmp-hold")) return this.hold(row)
    if (t.closest("[data-put]")) return this.#put(t.closest("[data-put]").dataset.put, row)
    if (t.closest("[data-plus]")) return this.#plus(row)
    if (t.closest("button")) return
    this.cursor = row.dataset.noteId
    this.#renderRows()
    this.#mark()
  }

  // ---------- moving the cursor ----------

  #moveCursor(by) {
    const others = this.#others
    const at = others.findIndex(row => row.dataset.noteId === this.cursor)
    const to = others[at < 0 ? (by > 0 ? 0 : others.length - 1) : Math.max(0, Math.min(others.length - 1, at + by))]
    if (!to) return
    this.cursor = to.dataset.noteId
    this.#renderRows()
    this.#mark()
    to.scrollIntoView({ block: "nearest", behavior: this.#motion })
  }

  // ---------- grouping ----------

  #put(labelId, row) {
    const on = labelIdsOf(row).includes(String(labelId))
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

  // Sends a change; the reply redraws the labels and the panel, and so this. Returns why it was refused, if
  // it was.
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
  // + or n a new group of the two, Enter holds it under a tab, [ and ] go from tab to tab, x lets the note you're on go,
  // J/K step the note you're on, p and o open the passage and the note, Esc closes what's open, then goes back.
  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest?.("input, textarea, select, [contenteditable]")) return
    const k = event.key
    if (!this.comparing) {
      if (k === "g" && !event.repeat && this.#here?.dataset.noteId) { event.preventDefault(); this.enter() }
      return
    }
    // Esc puts away the scratchpad or the labels first, if they're out (their own keys see to it).
    if (k === "Escape" && this.element.querySelector(".reread-pad:is(.open, .labels-open)")) return
    if (k === "g" || (k === "Escape" && !this.#closePeeks())) { event.preventDefault(); return this.leave() }
    if (k === "Escape") return event.preventDefault()
    const cursor = this.#rowOf(this.cursor)
    if (event.repeat && "jkJK[]".includes(k)) return event.preventDefault()
    if (k === "j" || k === "ArrowDown") this.#moveCursor(1)
    else if (k === "k" || k === "ArrowUp") this.#moveCursor(-1)
    else if (k === "J" || k === "ArrowRight") this.#step(1)
    else if (k === "K" || k === "ArrowLeft") this.#step(-1)
    else if (k === "]") this.#switchTab((this.#active + 1) % this.tabs.length)
    else if (k === "[") this.#switchTab((this.#active + this.tabs.length - 1) % this.tabs.length)
    else if (k === "x") this.#untab(this.#active)
    else if (/^[1-9]$/.test(k) && cursor) { const label = this.#mine[Number(k) - 1]; if (label) this.#put(label.id, cursor) }
    else if ((k === "+" || k === "=" || k === "n") && cursor) this.#plus(cursor)
    else if (k === "Enter" && cursor) this.hold(cursor)
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

const stripTags = html => { const div = document.createElement("div"); div.innerHTML = html; return div.textContent.trim() }
