// What the reread's controllers share about a note's row.

// A note's reference: its passage's ("Isaiah 40:6"), or its number on the focus ("focus 2"). A note on the whole
// focus written since the page loaded has only the number its reply put in its row.
export function citeOf(row) {
  if (!row) return ""
  if (row.dataset.cite) return row.dataset.cite
  const cite = row.querySelector(".rr-cite")?.textContent.trim() || ""
  return row.classList.contains("rr-free") ? cite.charAt(0).toLowerCase() + cite.slice(1) : cite
}

// "Isaiah 40:6" beside "Isaiah 40:7" is just "40:6"; from another work or chapter, the whole of it. A note on the
// whole focus is always "focus 2".
export function shortCite(cite = "", from = "") {
  if (cite.startsWith("focus ")) return cite
  const split = text => { const at = text.lastIndexOf(" "); return at < 0 ? [ "", text ] : [ text.slice(0, at), text.slice(at + 1) ] }
  const [ book, rest ] = split(cite), [ fromBook ] = split(from)
  return book && book === fromBook ? rest : cite
}

// A reference where room is short: a long title or name, which CSS cuts short, and its last part ("1:6"), which tells
// it from its neighbours and is never cut. A short one ("Isaiah 40:6", "focus 2") is left as it is.
export function condensedCite(cite = "") {
  const at = cite.lastIndexOf(" ")
  if (at <= 12) return escapeHtml(cite)
  return `<span class="ref-name">${escapeHtml(cite.slice(0, at))}</span> <span class="ref-at">${escapeHtml(cite.slice(at + 1))}</span>`
}

// The label ids a row's note carries.
export function labelIdsOf(row) { return (row?.querySelector("[data-label-ids]")?.dataset.labelIds || "").split(" ").filter(Boolean) }

export const escapeHtml = text => String(text).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
