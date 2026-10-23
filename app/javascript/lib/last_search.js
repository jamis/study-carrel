// The search you last made in this sitting (sessionStorage): its results page, and the result you opened from it as
// an #r-<unit id> anchor. The rail's and menu's Search links go back there instead of an empty search page.
const KEY = "study-last-search"

export const lastSearch = {
  get() { try { return sessionStorage.getItem(KEY) } catch { return null } },
  set(url) { try { sessionStorage.setItem(KEY, url) } catch {} }
}
