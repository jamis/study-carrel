// Reading a passage a clause at a time: the passage split at its punctuation, in the browser, for reading only.
// Notes, keeps and your place stay with the whole passage.

// Where a break may fall. A comma, semicolon or colon needs a space after it (so 1,000 and 3:16 hold together),
// past any closing quote or bracket; a dash breaks after itself, space or not; parentheses break before ( and after ).
// A verse can hold several sentences (Jonah 4:2), so . ? ! break too, the same way, but a period not after an
// abbreviation or an initial (Mr. St. i.e. J. S. Mill; "I." still ends one). A lone word left over joins the next.
export const MARKS = [
  { key: ".?!", re: /(?<!\b(?:Mr|Mrs|Ms|Dr|St|Mt|Messrs|vol|viz|cf|ch|pp?|No|[A-HJ-Z]|i\.e|e\.g))\.[’”'")\]]*\s+|[?!][’”'")\]]*\s+/g },
  { key: ",", re: /,[’”'")\]]*\s+/g },
  { key: ";", re: /;[’”'")\]]*\s+/g },
  { key: ":", re: /:[’”'")\]]*\s+/g },
  { key: "—", re: /—[’”'"]*\s*/g },
  { key: "()", re: /\s+(?=\()|\)[’”'"]*\s+/g }
]
const DEFAULT_BREAKS = [".?!", ",", ";", ":", "—"]

// The clauses of a passage, each { text, gap } with the whitespace after it, so joining them gives back the passage.
// A lone word ("Well," "Simplify,") joins the clause after it; a lone last word joins the one before. Two words
// stand alone ("no invention, no hope."): better to split too often than too seldom.
export function splitClauses(text, breaks) {
  const cuts = new Set()
  MARKS.forEach(({ key, re }) => {
    if (!breaks.has(key)) return
    for (const match of text.matchAll(re)) {
      const at = match.index + match[0].length
      if (at > 0 && at < text.length) cuts.add(at)
    }
  })
  const at = [0, ...[...cuts].sort((a, b) => a - b), text.length]
  const clauses = []
  for (let i = 0; i < at.length - 1; i++) {
    const raw = text.slice(at[i], at[i + 1]), body = raw.trimEnd()
    if (body) clauses.push({ text: body, gap: raw.slice(body.length) })
  }

  const join = (a, b) => ({ text: a.text + a.gap + b.text, gap: b.gap })
  const lone = (c) => c.text.split(/\s+/).filter(Boolean).length < 2
  for (let i = 0; i < clauses.length - 1;) {
    if (lone(clauses[i])) clauses.splice(i, 2, join(clauses[i], clauses[i + 1]))
    else i++
  }
  if (clauses.length > 1 && lone(clauses.at(-1))) clauses.splice(-2, 2, join(clauses.at(-2), clauses.at(-1)))
  return clauses
}

// Where to break is a reading preference, kept in this browser.
const BREAKS_KEY = "study-clause-breaks"
export function savedBreaks() {
  try {
    const saved = JSON.parse(localStorage.getItem(BREAKS_KEY))
    if (Array.isArray(saved)) return new Set(saved)
  } catch {}
  return new Set(DEFAULT_BREAKS)
}
export function saveBreaks(breaks) {
  try { localStorage.setItem(BREAKS_KEY, JSON.stringify([...breaks])) } catch {}
}

// Reading by clause is off until you turn it on, and then stays on, from passage to passage and chapter to chapter,
// until you turn it off or leave the reader (see application.js). "last" means: start on the last clause, having
// stepped back into the previous chapter.
const MODE_KEY = "study-clauses"
export const clauseMode = {
  get() { try { return sessionStorage.getItem(MODE_KEY) } catch { return null } },
  set(value) {
    try { value ? sessionStorage.setItem(MODE_KEY, value) : sessionStorage.removeItem(MODE_KEY) } catch {}
  }
}
