// The search you last made in this sitting (sessionStorage): its results page, and the result you opened from it as
// an #r-<unit id> anchor. Opening a result also puts up the reader's "Back to results" slip, which stays while you
// read on and goes when you leave the reader, or by its ×.
const KEY = "study-last-search"
const SLIP = "study-back-to-results"

function get(key) { try { return sessionStorage.getItem(key) } catch { return null } }
function set(key, value) { try { value == null ? sessionStorage.removeItem(key) : sessionStorage.setItem(key, value) } catch {} }

export const lastSearch = {
  get() { return get(KEY) },
  set(url) { set(KEY, url) },
  // What it searched for, to name it ("light").
  query() {
    const url = get(KEY)
    return url ? new URL(url, location.origin).searchParams.get("q") : null
  },
  // Names it in a <q>, which adds its own quote marks unless the query has some already ("search query", or
  // holy "the word"), when it's shown as typed.
  name(q, query) {
    q.textContent = query
    q.classList.toggle("verbatim", query.includes('"'))
  },
  get slip() { return get(SLIP) === "1" },
  set slip(up) { set(SLIP, up ? "1" : null) }
}
